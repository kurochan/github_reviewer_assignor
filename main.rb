require "#{File.expand_path("../", __FILE__)}/config.rb"

['lib', 'ext'].each do |path|
  Dir[File.expand_path("../#{path}", __FILE__) << '/*.rb'].each do |file|
    require file
  end
end

puts "github repository: #{GITHUB_OWNER}/#{GIT_REPOSITORY}"

git = Git.new(GIT_REPOSITORY, GITHUB_OWNER, GIT_LOCAL_REPOSITORY_PATH)

github = Github.new(GITHUB_API_TOKEN)
req = github.pull_request("#{GITHUB_OWNER}/#{GIT_REPOSITORY}", 3344)
user = req.head.user.login
base_branch = req.base.ref
base_sha = req.base.ref
head_branch = req.head.ref
head_sha = req.head.sha

git.update_base_branch(base_branch)
git.fetch_remote_branch(user, head_branch)

params = SolverParams.new("#{GIT_LOCAL_REPOSITORY_PATH}/#{GIT_REPOSITORY}", base_sha, head_sha)
if params.file_list.empty?
  puts "No changed file was found!"
  exit 0
end

history_summary = HistorySummary.new(params)
reviewers, unreviewable_files = SetCoverProblemSolver.solve(history_summary)

reviewers.each do |author_email|
  puts author_email
  puts history_summary.author_email_to_data[author_email].files.keys
end

if !unreviewable_files.empty?
  puts "no one can review"
  unreviewable_files.each do |file|
    puts file
  end
end
