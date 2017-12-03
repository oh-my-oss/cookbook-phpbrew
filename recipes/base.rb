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

user "deploy" do
    uid 1000
    comment "for deployment"
    home "/home/deploy"
    shell "/bin/bash"
    password nil
    action :create
end

directory "/home/deploy" do
    owner "deploy"
    group "deploy"
    mode 0700
    recursive true
    action :create
end

directory "/home/deploy/.ssh" do
    owner "deploy"
    group "deploy"
    mode 0700
    recursive true
    action :create
end

directory "/var/www/sites" do
    owner "deploy"
    group "deploy"
    recursive true
    mode 0755
    action :create
end

directory "/usr/local/lib64/phpbrew" do
    owner "root"
    group "root"
    mode 0755
    action :create
end

group "deploy" do
    gid 1000
    members ['deploy']
    action :create
end
