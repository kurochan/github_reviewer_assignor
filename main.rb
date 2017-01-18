require "#{File.expand_path("../", __FILE__)}/config.rb"

['lib'].each do |path|
  Dir[File.expand_path("../#{path}", __FILE__) << '/*.rb'].each do |file|
    require file
  end
end

puts "github repository: #{GITHUB_OWNER}/#{GIT_REPOSITORY}"

git = Git.new(GIT_REPOSITORY, GITHUB_OWNER, GIT_LOCAL_REPOSITORY_PATH)

github = Github.new(GITHUB_API_TOKEN)
reqs = github.pull_requests("#{GITHUB_OWNER}/#{GIT_REPOSITORY}").select {|req| req.requested_reviewers.empty? }
members = github.team_members(GITHUB_TEAM_ID).map {|member| member.login}

reqs.each do |req|
  title = req.title
  req_user = req.head.user.login
  base_branch = req.base.ref
  base_sha = req.base.ref
  head_branch = req.head.ref
  head_sha = req.head.sha

  git.update_base_branch(base_branch)
  git.fetch_remote_branch(req_user, head_branch)

  params = SolverParams.new("#{GIT_LOCAL_REPOSITORY_PATH}/#{GIT_REPOSITORY}", base_sha, head_sha)
  if params.file_list.empty?
    puts "No changed file was found!"
    exit 0
  end

  history_summary = HistorySummary.new(params)
  reviewers, unreviewable_files = SetCoverProblemSolver.solve(history_summary)

  reviewers = reviewers.map {|email| MAIL_GITHUB_ID_MAPPING[email] ? MAIL_GITHUB_ID_MAPPING[email] : email }
  active_users = reviewers & members - [req_user]
  inactive_users = reviewers - members - [req_user]

  next if active_users.empty?

  puts ""
  puts "# #{title}"

  puts "### all"
  reviewers.each do |user|
    puts "#{user}"
  end

  puts "## reviewers"
  puts "### active"
  active_users.each do |user|
    puts "@#{user}"
  end

  github.add_reviewers("#{GITHUB_OWNER}/#{GIT_REPOSITORY}", req.number, active_users)

  puts "### inactive"
  inactive_users.each do |user|
    puts "#{user}"
  end

  if !unreviewable_files.empty?
    puts "## no one can review"
    unreviewable_files.each do |file|
      puts file
    end
  end
end
