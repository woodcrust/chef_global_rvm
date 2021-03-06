require_relative '../libraries/helpers'

actions :install
default_action :install

property :name,     String, name_attribute: true
property :users,    Array,  required: true
property :rvm_path, String, required: true

action :install do
  break unless rvm_exist?

  new_resource.users.each do |user|
    next if belong_to_rvm_group?(user)

    ruby_block "export rvm_path #{rvm_path} to /etc/profile" do
      rvm_export_path        = %(export rvm_path=#{rvm_path}\nexport PATH=$PATH:#{rvm_path}/rubies/default/bin)
      rvm_export_path_regexp = /rvm/

      block do
        file = Chef::Util::FileEdit.new('/etc/profile')
        file.insert_line_if_no_match(rvm_export_path_regexp, "\n#{rvm_export_path}")
        file.write_file
      end
    end

    ruby_block "export rvm env to user profile" do
      rvm_export_path        = %(export PATH="$PATH:#{rvm_path}/bin"\n[[ -s "#{rvm_path}/scripts/rvm" ]] && source "#{rvm_path}/scripts/rvm"\nexport PATH=$PATH:#{rvm_path}/rubies/default/bin)
      rvm_export_path_regexp = /#{rvm_path}\/scripts\/rvm/

      block do
        file = Chef::Util::FileEdit.new("/home/#{user}/.profile")
        file.insert_line_if_no_match(rvm_export_path_regexp, "\n#{rvm_export_path}")
        file.write_file

        file = Chef::Util::FileEdit.new("/home/#{user}/.bashrc")
        file.insert_line_if_no_match(rvm_export_path_regexp, "\n#{rvm_export_path}")
        file.write_file
      end
    end

    execute "add rvm to user: #{user}" do
      command "gpasswd -a #{user} rvm"
    end
  end
end

action_class do
  include GlobalRvmHelper
end