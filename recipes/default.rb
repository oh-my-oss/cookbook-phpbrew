#
# Cookbook:: phpbrew
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

include_recipe 'phpbrew::base'

execute 'install phpbrew' do
    command 'curl -L -O https://github.com/phpbrew/phpbrew/raw/master/phpbrew && chmod +x phpbrew && sudo mv phpbrew /usr/local/bin/phpbrew'
    not_if { File.exists?('/usr/local/bin/phpbrew') }
end

execute 'setup bashrc' do
    command "echo 'export PATH=$PATH:/usr/local/bin' >> /etc/bashrc"
    not_if "grep 'export PATH=$PATH:/usr/local/bin' /etc/bashrc"
end

execute 'setup bashrc2' do
    command "echo 'export PHPBREW_ROOT=/usr/local/lib64/phpbrew' >> /etc/bashrc"
    not_if "grep 'export PHPBREW_ROOT=/usr/local/lib64/phpbrew' /etc/bashrc"
end

execute 'setup bashrc3' do
    command "echo '[[ -e /usr/local/lib64/phpbrew/bashrc ]] && source /usr/local/lib64/phpbrew/bashrc' >> /etc/bashrc"
    not_if "grep '[[ -e /usr/local/lib64/phpbrew/bashrc ]] && source /usr/local/lib64/phpbrew/bashrc' /etc/bashrc"
end

execute 'phpbrew init' do
    command "phpbrew init"
    environment(
        "PATH" => "/usr/local/bin:#{ENV['PATH']}",
        "PHPBREW_ROOT" => "/usr/local/lib64/phpbrew"
    )
    not_if { File.exists?('/usr/local/lib64/phpbrew/php-releases.json') }
end

execute 'phpbrew known --update --old' do
    command "phpbrew known --update --old"
    environment(
        "PATH" => "/usr/local/bin:#{ENV['PATH']}",
        "PHPBREW_ROOT" => "/usr/local/lib64/phpbrew"
    )
end

node['php_versions'].each do |version|
    execute 'php' + version + ' install' do
        command 'phpbrew install ' + version + ' ' + node['phpbrew_install_arg'] + ' -- --with-libdir=lib64'
        environment(
            "PATH" => "/usr/local/bin:#{ENV['PATH']}",
            "PHPBREW_ROOT" => "/usr/local/lib64/phpbrew"
        )
        not_if { File.exists?('/usr/local/lib64/phpbrew/php/php-' + version + '/bin/php') }
    end

    template '/etc/init.d/php-fpm-' + version do
        owner 'root'
        mode 0755
        source 'php-fpm.erb'
        variables({
            :php_version => 'php-' + version
        })
    end

    execute 'php-fpm chkconfig - ' + version  do
        command 'chkconfig --add php-fpm-' + version
        not_if 'chkconfig --list php-fpm-' + version
    end

    execute 'service php-fpm start - ' + version  do
        command 'service php-fpm-' + version + ' start'
        not_if { File.exists?('/usr/local/lib64/phpbrew/php/php-' + version + '/var/run/php-fpm.pid') }
    end
end
