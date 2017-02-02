require 'octokit'

class Github
  attr_reader :client

  def initialize(token)
    @client = Octokit::Client.new access_token: token
  end

  def team_members(team_id)
    @client.team_members(team_id)
  end

  def pull_requests(repository)
    client.pull_requests repository, :accept => 'application/vnd.github.black-cat-preview+json'
  end

  def pull_request(repository, id)
    client.pull_request repository, id, :accept => 'application/vnd.github.black-cat-preview+json'
  end

  def get_reviewers(repository, id)
    client.get "/repos/#{repository}/pulls/#{id}/reviews", :accept => 'application/vnd.github.black-cat-preview+json'
  end

  def add_reviewers(repository, id, reviewers)
    params = {
      :reviewers => reviewers,
      :accept => 'application/vnd.github.black-cat-preview+json'
    }
    client.post "/repos/#{repository}/pulls/#{id}/requested_reviewers", params
  end
end
