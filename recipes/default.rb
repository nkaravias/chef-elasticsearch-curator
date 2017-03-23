#
# Cookbook Name:: omc_curator
# Recipe:: default
#
# Copyright 2017, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
image_uri=::File.join(node[:omc_curator][:registry],node[:omc_curator][:image])
Chef::Log.info("Attempting to pull docker image #{image_uri}")

directory node[:omc_curator][:curator_workdir] do
  owner 'root'
  group 'root'
  action :create
end

directory node[:omc_curator][:ssl_path] do
  owner 'root'
  group 'root'
  mode '0700'
  action :create
end

# Render certificates if available
if node['omc_curator']['curator_ssl_dbag_info'].empty?
 Chef::Log.info("There is not curator data bag ssl configuration set. Check node['omc_curator']['curator_ssl_dbag_info']")
else
  dbag = node['omc_curator']['curator_ssl_dbag_info'].keys.first
  dbag_item = node['omc_curator']['curator_ssl_dbag_info'][dbag]
  Chef::Log.info("Attempting to load ssl dbag info for: #{dbag}::#{dbag_item}")
  dbag_obj = Chef::EncryptedDataBagItem.load(dbag, dbag_item)
  { "es.pem":"elasticsearch.ssl.cert", "es-key.pem":"elasticsearch.ssl.key", "ca.pem":"ca.ssl.cert" }.each do |filename, dbag_key|
    Chef::Log.info("#{filename}::#{dbag_key}")
    file ::File.join(node[:omc_curator][:ssl_path],filename.to_s) do
      owner 'root'
      group 'root'
      mode '0700'
      content Base64.decode64(dbag_obj[dbag_key])
    end
  end
end

if node['omc_curator']['curator_dbag_info'].empty? 
 Chef::Log.info("There is not curator data bag configuration set. Check node['omc_curator']['curator_dbag_info']")
else
  # Update image
  docker_image image_uri do
    tag node[:omc_curator][:tag]
    action :pull
  end
  # Load configuration
  node['omc_curator']['curator_dbag_info'].each do |dbag_info|
    dbag = dbag_info.keys.first
    dbag_item = dbag_info[dbag]
    Chef::Log.info("Attempting to load #{dbag}::#{dbag_item}")
    dbag_obj = Chef::EncryptedDataBagItem.load(dbag, dbag_item)
    env_attrs=dbag_obj['env_attrs'].map { |key,value| key+'='+value.to_s }

    docker_container dbag_obj['hostname'] do
      repo image_uri
      env env_attrs
      tag node[:omc_curator][:tag]
      volumes [ "#{node[:omc_curator][:ssl_path]}:/ssl", "/var/log/#{dbag_obj['hostname']}:/logs" ]
      working_dir node[:omc_curator][:curator_workdir]
      kill_after 30
      restart_policy 'always'
      action :run
      subscribes :redeploy,"docker_image[#{image_uri}]",:immediately
    end

  end
end
