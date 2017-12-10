%w(libxml2-devel openssl-devel bzip2-devel libcurl-devel readline-devel libxslt-devel libmcrypt-devel).each do |pkg|
    package pkg
end

%w(php70 php70-common php70-devel).each do |pkg|
    package pkg
end

directory "/usr/local/lib64/phpbrew" do
    owner "root"
    group "root"
    mode 0755
    action :create
end

template '/etc/php-7.0.d/99-timezone.ini' do
    owner 'root'
    mode 0755
    source '99-timezone.ini.erb'
end
