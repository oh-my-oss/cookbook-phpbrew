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
    command "echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc && export PATH=$PATH:/usr/local/bin"
end

execute 'phpbrew init' do
    command "/usr/local/bin/phpbrew init && echo '[[ -e ~/.phpbrew/bashrc ]] && source ~/.phpbrew/bashrc' >> ~/.bashrc && . ~/.bashrc && /usr/local/bin/phpbrew known"
    not_if { Dir.exists?('~/.phpbrew') }
end

execute 'phpbrew init' do
    command "/usr/local/bin/phpbrew init && echo '[[ -e ~/.phpbrew/bashrc ]] && source ~/.phpbrew/bashrc' >> ~/.bashrc && . ~/.bashrc && /usr/local/bin/phpbrew known"
    not_if { Dir.exists?('~/.phpbrew') }
end

node['php_versions'].each do |version|
    execute 'php' + version + ' install' do
        command 'sudo /usr/local/bin/phpbrew install ' + version + ' ' + node['phpbrew_install_arg'] + ' -- --with-libdir=lib64'
        not_if { File.exists?('/root/.phpbrew/php/php-' + version + '/bin/php') }
    end
end
