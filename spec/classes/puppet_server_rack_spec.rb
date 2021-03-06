require 'spec_helper'

describe 'puppet::server::rack' do
  on_os_under_test.each do |os, facts|
    next if facts[:osfamily] == 'windows'
    context "on #{os}" do
      if Puppet.version < '4.0'
        additional_facts = {}
      else
        additional_facts = {:rubysitedir => '/opt/puppetlabs/puppet/lib/ruby/site_ruby/2.1.0'}
      end

      let(:facts) do
        facts.merge(additional_facts)
      end

      let(:default_params) do {
        :app_root       => '/etc/puppet/rack',
        :confdir        => '/etc/puppet',
        :vardir         => '/var/lib/puppet',
        :user           => 'puppet',
        :rack_arguments => [],
      } end

      describe 'defaults' do
        let(:params) { default_params }

        it 'should create server_app_root' do
          should contain_file('/etc/puppet/rack').with({
            :ensure => 'directory',
            :owner  => 'puppet',
            :mode   => '0755',
          })
        end

        it 'should create server_app_root public' do
          should contain_file('/etc/puppet/rack/public').with({
            :ensure => 'directory',
            :owner  => 'puppet',
            :mode   => '0755',
          })
        end

        it 'should create server_app_root tmp' do
          should contain_file('/etc/puppet/rack/tmp').with({
            :ensure => 'directory',
            :owner  => 'puppet',
            :mode   => '0755',
          })
        end

        it 'should create config.ru' do
          should contain_file('/etc/puppet/rack/config.ru').with({
            :owner  => 'puppet',
          })
        end

        it 'should manage config.ru contents' do
          verify_exact_contents(catalogue, '/etc/puppet/rack/config.ru', [
            '$0 = "master"',
            'ARGV << "--rack"',
            'ARGV << "--confdir" << "/etc/puppet"',
            'ARGV << "--vardir"  << "/var/lib/puppet"',
            'Encoding.default_external = Encoding::UTF_8 if defined? Encoding',
            'require \'puppet/util/command_line\'',
            'run Puppet::Util::CommandLine.new.execute',
          ])
        end
      end

      describe 'when rack_arguments defined' do
        let(:params) { default_params.merge(:rack_arguments => ['--profile', '--logdest', '/dne/log']) }

        it 'should set ARGV values' do
          verify_contents(catalogue, '/etc/puppet/rack/config.ru', [
            'ARGV << "--rack"',
            'ARGV << "--confdir" << "/etc/puppet"',
            'ARGV << "--vardir"  << "/var/lib/puppet"',
            'ARGV << "--profile"',
            'ARGV << "--logdest"',
            'ARGV << "/dne/log"',
          ])
        end
      end

    end
  end
end
