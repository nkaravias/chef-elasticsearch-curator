reboot 'now' do
  action :nothing
  reason 'Reboot required to load latest UEK kernel'
end

cookbook_file '/etc/yum.repos.d/uek4.repo' do
  source 'uek4.repo'
end

yum_package 'kernel-uek' do
  version node['curator_kitchen_helper']['kernel_version']
end

yum_package 'kernel-uek-devel' do
  version node['curator_kitchen_helper']['kernel_version']
  notifies :reboot_now,'reboot[now]',:immediately
end
