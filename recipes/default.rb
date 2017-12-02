#
# Cookbook:: phpbrew
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

execute "change localtime to JST 1" do
    user "root"
    command "cp -p /usr/share/zoneinfo/Japan /etc/localtime"
    not_if "diff /usr/share/zoneinfo/Japan /etc/localtime"
end

execute "change localtime to JST 2" do
    user "root"
    command "echo 'ZONE=\"Asia/Tokyo\"' > /etc/sysconfig/clock"
    not_if "grep 'ZONE=\"Asia/Tokyo\"' /etc/sysconfig/clock"
end

execute "change localtime to JST 3" do
    user "root"
    command "echo 'UTC=false' >> /etc/sysconfig/clock"
    not_if "grep 'UTC=false' /etc/sysconfig/clock"
end

%w(php70 php70-common php70-devel php70-mbstring php70-mcrypt php7-pear).each do |pkg|
    package pkg
end

%w(libxml2-devel openssl-devel bzip2-devel libcurl-devel readline-devel libxslt-devel libmcrypt-devel).each do |pkg|
    package pkg
end

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
    end
end
