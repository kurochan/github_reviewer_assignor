module Octokit
  class Client
    module Reviewers
      def add_reviewers(repo, reviewers, options = {})
        params = {}
        puts params
      end
    end
  end
end

module Octokit
  class Client
    include Octokit::Client::Reviewers
  end
end
