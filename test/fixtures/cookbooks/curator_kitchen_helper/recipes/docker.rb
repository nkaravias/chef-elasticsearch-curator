if /^4.*/.match(node[:kernel][:release])
  template '/etc/yum.repos.d/docker.repo' do
   source 'repos/docker.repo.erb'
  end

  yum_package 'docker-engine' do
    version node['curator_kitchen_helper']['docker']['version']
    action :install
  end

  directory '/etc/systemd/system/docker.service.d' do
    recursive true
  end

  template '/etc/systemd/system/docker.service' do
    source 'docker.service.erb'
#    action :create_if_missing
  end

#  template '/etc/systemd/system/docker.service.d/http-proxy.conf' do
#    source 'docker/http-proxy.conf.erb'
##    action :create_if_missing
#  end

  group 'docker' do
    action :modify
    members 'vagrant'
    append true
  end

  service 'docker' do
    action [:enable, :start]
  end
end
