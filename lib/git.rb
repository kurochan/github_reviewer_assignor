class Git

  def initialize(repository_name, owner, local_path)
    @repository_name = repository_name
    @owner = owner
    @local_path = local_path

    clone_repository unless repository_exist?
  end

  def repository_exist?
    Dir.exist?("#{@local_path}/#{@repository_name}")
  end

  def clone_repository
    puts "clone into #{@local_path}/#{@repository_name}"
    `cd #{@local_path} && git clone git@github.com:#{@owner}/#{@repository_name} #{@repository_name} 2>&1 > /dev/null`
  end

  def update_base_branch(branch)
    `cd #{@local_path}/#{@repository_name} && git checkout #{branch} 2>&1 > /dev/null`
    `cd #{@local_path}/#{@repository_name} && git pull origin #{branch} 2>&1 > /dev/null`
  end

  def fetch_remote_branch(user, branch)
    `cd #{@local_path}/#{@repository_name} && git remote add #{user} git@github.com:#{user}/#{@repository_name} 2>&1 > /dev/null`
    `cd #{@local_path}/#{@repository_name} && git fetch -f #{user} #{branch} 2>&1 > /dev/null`
  end
end
