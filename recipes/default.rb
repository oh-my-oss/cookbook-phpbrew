#
# Cookbook:: phpbrew
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

include_recipe 'base::default'
include_recipe 'phpbrew::base'

execute 'install phpbrew' do
    cwd '/tmp'
    command 'curl -L -O https://github.com/phpbrew/phpbrew/raw/master/phpbrew && chmod +x phpbrew && sudo mv phpbrew /usr/local/bin/phpbrew'
    not_if { File.exists?('/usr/local/bin/phpbrew') }
end

execute 'setup bashrc' do
    command "echo 'export PATH=$PATH:/usr/local/bin:/usr/local/lib64/phpbrew/bin' >> /etc/bashrc"
    not_if "grep 'export PATH=$PATH:/usr/local/bin:/usr/local/lib64/phpbrew/bin' /etc/bashrc"
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

directory "/usr/local/lib64/phpbrew/bin" do
    recursive true
    action :create
end

execute 'phpbrew known --update --old' do
    command "phpbrew known --update --old"
    environment(
        "PATH" => "/usr/local/bin:#{ENV['PATH']}",
        "PHPBREW_ROOT" => "/usr/local/lib64/phpbrew"
    )
    not_if 'find /usr/local/lib64/phpbrew/php-releases.json -ctime -9' # 最後に更新したのが10日以上前
end

execute 'setup composer' do
    command "phpbrew app get composer"
    environment(
        "PATH" => "/usr/local/bin:#{ENV['PATH']}",
        "PHPBREW_ROOT" => "/usr/local/lib64/phpbrew"
    )
    not_if { File.exists?('/usr/local/lib64/phpbrew/bin/composer') }
end

bash 'update .phpbrew/bashrc setting' do
    code <<-EOH
        for i in `cat /etc/passwd|cut -d: -f6,7|grep '/bin/bash$'|cut -d: -f1|grep -v /root`;
        do
            if [ $(grep '[ -f ~/.phpbrew/bashrc ] && . ~/.phpbrew/bashrc' $i/.bashrc|wc -l ) -eq 0 ]; then
                if [ -f /home/mysql/.bashrc ]; then
                    echo "update $i/.bashrc"
                    echo '[ -f ~/.phpbrew/bashrc ] && . ~/.phpbrew/bashrc' >> $i/.bashrc
                fi
            fi
        done
    EOH
end

bash 'copy .phpbrew dir' do
    code <<-EOH
        for i in `cat /etc/passwd|cut -d: -f6,7|grep '/bin/bash$'|cut -d: -f1|grep -v /root`;
        do
            if [ -d $i ]; then
                if [ ! -d $i/.phpbrew ]; then
                    if [ -d /root/.phpbrew ]; then
                        echo "create $i/.phpbrew"
                        cp -rf /root/.phpbrew $i/ && chown -R $(basename $i):$(basename $i) $i/.phpbrew;
                    fi
                fi
            fi
        done
    EOH
end

node['php_versions'].each do |version|
    execute 'php' + version + ' install' do
        command 'phpbrew install ' + version + ' ' + node['phpbrew_install_arg'] + ' +fpm -- --with-libdir=lib64'
        environment(
            "PATH" => "/usr/local/bin:#{ENV['PATH']}",
            "PHPBREW_ROOT" => "/usr/local/lib64/phpbrew"
        )
        not_if { File.exists?('/usr/local/lib64/phpbrew/php/php-' + version + '/bin/php') }
    end

    execute 'service php-fpm set config user - ' + version  do
        command 'echo "user = apache" >> /usr/local/lib64/phpbrew/php/php-' + version + '/etc/php-fpm.conf'
        not_if 'grep "user = apache" /usr/local/lib64/phpbrew/php/php-' + version + '/etc/php-fpm.conf'
    end

    execute 'service php-fpm set config group - ' + version  do
        command 'echo "group = apache" >> /usr/local/lib64/phpbrew/php/php-' + version + '/etc/php-fpm.conf'
        not_if 'grep "group = apache" /usr/local/lib64/phpbrew/php/php-' + version + '/etc/php-fpm.conf'
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

    directory "/var/www/sites/php-" + version do
        owner "deploy"
        group "deploy"
        mode 0755
        recursive true
        action :create
        only_if { Dir.exists?('/etc/httpd') }
    end

    template '/etc/httpd/conf.d/vhost-php-fpm-' + version + '.conf' do
        owner 'root'
        mode 0755
        source 'vhost-php-fpm.conf.erb'
        variables({
            :version => version
        })
        notifies :restart, "service[httpd]"
        only_if { Dir.exists?('/etc/httpd') }
    end

    ## テスト用の仮環境 phpinfo()
    execute 'ln -s /vagrant/src/test /var/www/sites/php-' + version + '/'  do
        command 'ln -s /vagrant/src/test /var/www/sites/php-' + version + '/'
        not_if { Dir.exists?('/var/www/sites/php-' + version + '/test') }
    end
    ## テスト用の仮環境 ここまで
end
