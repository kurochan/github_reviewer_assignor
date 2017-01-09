# MIT License
# 
# Copyright (c) 2016 munetoshi
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'open3'
require 'set'
require 'shellwords'

#
# Keeps a list of files to be reviewed and other options to suggest reviewers
#
class SolverParams
  attr_reader :file_list, :excluded_authors, :history_depth,
    :candidate_limit, :external_command_executor

  def initialize(base_path, diff1, diff2)
    @excluded_authors = []
    @history_depth = 100
    @candidate_limit = 10
    @includes_myself = false

    @external_command_executor = ExternalCommandExecutor.new(base_path)

    @file_list = @external_command_executor.git_diff_files(diff1, diff2)

    my_email = @external_command_executor.git_my_email
    @excluded_authors.push(my_email) if !@includes_myself && !my_email.empty?
  end
end

#
# Collection of utility methods to call the external commands, "git" and "tput".
#
class ExternalCommandExecutor
  attr_reader :base_dir

  def initialize(base_dir = '.')
    @base_dir = base_dir
  end

  def git_my_email
    call("git config user.email").chomp
  end

  def git_diff_files(diff_base, diff_target)
    call("git diff #{diff_base}...#{diff_target} --name-only").lines.map(&:chomp)
  end

  def git_history(file, excluded_authors, history_depth, candidate_limit)
    filter_author_command =  excluded_authors.empty? ?
      "" : "| egrep -v \"" + excluded_authors.join("|") + "\" "
    command = "git log --pretty=\"%ae\" #{file} | head -#{history_depth} " +
      filter_author_command + "| sort | uniq -c | sort -nr | head -#{candidate_limit}"
    call(command).lines.map(&:chomp)
  end

  private

  def call(external_command_string)
    command = "cd #{@base_dir.shellescape} && #{external_command_string}"
    Open3.capture3(command)[0]
  end
end

#
# Author data holding pairs of file names and scores.
#
class AuthorData
  attr_reader :files

  def initialize
    @files = {}
  end

  def add_file(file, score)
    if score > 0
      @files[file] = score
    else
      @files.delete(file)
    end
  end

  def total_score_for(files)
    score = 0
    files.each do |file|
      score += score_for(file)
    end
    score
  end

  def elements
    @files.keys
  end

  def score_for(file)
    @files[file] || 0
  end
end

#
# Solver of the set cover problem which is finding a combination of sets to cover all the elements.
# To avoid confusion with Ruby's "Set", we use the term "group" to mean "set" in this class.
#
class SetCoverProblemSolver

  # Solves the set cover problem using the greedy algorithm
  # @return [Set, Set]
  #   First value: Set of group IDs to cover elements.
  #   Second value: Set of elements which is not covered by any group.
  def self.solve(history_summary)
    elements = Set.new(history_summary.file_to_authors.keys)
    groups = history_summary.author_email_to_data

    uncovered_elements = elements.clone
    uncovering_group_ids = Set.new(groups.keys)

    while !uncovered_elements.empty?
      candidate_id = nil
      candidate_score = 0

      # Choose the best group for uncovered elements
      uncovering_group_ids.each do |group_id|
        group_data = groups[group_id]
        next unless group_data

        score = group_data.total_score_for(uncovered_elements)
        if candidate_score < score
          candidate_id = group_id
          candidate_score = score
        end
      end

      break unless candidate_id

      uncovering_group_ids.delete(candidate_id)
      uncovered_elements -= groups[candidate_id].elements
    end

    return Set.new(groups.keys) - uncovering_group_ids, uncovered_elements
  end
end

class HistorySummary
  attr_reader :author_email_to_data, :file_to_authors

  def initialize(params)
    @author_email_to_data = {}
    @file_to_authors = {}
    create_author_summary(params)
  end

  private

  def create_author_summary(params)

    external_command_executor = params.external_command_executor

    params.file_list.each do |file|
      @file_to_authors[file] = Set.new
      top_score = nil
      history_results = external_command_executor.git_history(
        file, params.excluded_authors, params.history_depth, params.candidate_limit)

      history_results.each do |result|
        match_result = result.match(/(\d+)\s+(\S+)/)
        next unless match_result
    
        score = match_result[1].to_f
        top_score ||= score
        author_email = match_result[2]
        @author_email_to_data[author_email] ||= AuthorData.new
        @author_email_to_data[author_email].add_file(file, score / top_score)
        @file_to_authors[file].add(author_email)
      end
    end
  end
end
