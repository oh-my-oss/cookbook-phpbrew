%w(libxml2-devel openssl-devel bzip2-devel libcurl-devel readline-devel libxslt-devel libmcrypt-devel).each do |pkg|
    package pkg
end

directory "/usr/local/lib64/phpbrew" do
    owner "root"
    group "root"
    mode 0755
    action :create
end
