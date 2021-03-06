require 'spec_helper'

describe 'accounts', :type => :class do
  let(:facts) { {
    :osfamily => 'Debian',
    :puppetversion => Puppet.version,
  } }
  let(:params){{
    :manage_users  => true,
    :manage_groups => true,
  }}

  it { should compile.with_all_deps }
  it { should contain_class('accounts::users') }
  it { should contain_class('accounts::groups') }

  context 'allow passing users and groups directly to init class' do
    let(:params){{
      :users => { 'john' => { 'comment' => 'John Doe', 'gid' => 2001 }},
      :groups => { 'developers' => { 'gid' => 2001 }}
    }}

    it { should contain_user('john').with(
      'comment' => 'John Doe',
      'gid' => 2001
    )}

    it { should contain_group('developers').with(
      'gid'    => 2001,
      'ensure' => 'present'
    )}
  end

  context 'no group management' do
    let(:params){{
      :users => { 'john' => { 'comment' => 'John Doe', 'gid' => 'john' }},
      :groups => { 'developers' => { 'gid' => 2001 }},
      :manage_groups => false,
    }}

    it { should contain_user('john').with(
      'comment' => 'John Doe',
      'gid' => 'john'
    )}

    it { should_not contain_group('developers').with(
      'gid'    => 2001,
      'ensure' => 'present'
    )}

  end

  context 'test hiera fixtures' do
    if Gem::Version.new(Puppet.version) >= Gem::Version.new('3.6.0')
      it { should contain_user('myuser').with(
        'uid' => 1000,
        'comment' => 'My Awesome User',
        'purge_ssh_keys' => true,
      )}
    else
      it { should contain_user('myuser').with(
        'uid' => 1000,
        'comment' => 'My Awesome User',
        # no purge_ssh_keys attribute
      )}
    end

    it { should contain_ssh_authorized_key('myawesomefirstkey').with(
      'type' => 'ssh-rsa',
      'key' => 'yay',
    )}

    it { should contain_ssh_authorized_key('myawesomesecondkey').with(
      'type' => 'ssh-rsa',
      'key' => 'hey',
    )}

    context 'root account' do
      it { should contain_user('root').with(
        'uid' => 0,
        'shell' => '/bin/bash',
      )}

      it { should contain_group('root').with(
        'gid'    => 0,
        'ensure' => 'present'
      )}

      it { should contain_file("/root").with({
        'ensure'  => 'directory',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0755'
      }) }

      it { should contain_ssh_authorized_key('root_key1').with(
        'type' => 'ssh-rsa',
        'key'  => 'AAA_key1',
        'user' => 'root',
      )}

      it { should contain_ssh_authorized_key('root_key2').with(
        'type' => 'ssh-rsa',
        'key'  => 'AAA_key2',
        'user' => 'root',
      )}
    end

    context 'superman account' do
      it { should contain_user('superman').with(
        'shell' => '/bin/bash',
      )}

      it { should contain_group('superman').with(
        'ensure' => 'present'
      )}

      it { should contain_group('superheroes').with(
        'ensure' => 'present',
        'members' => ['superman', 'batman']
      )}

      it { should contain_group('sudo').with(
        'ensure' => 'present',
      )}

      it { should contain_ssh_authorized_key('super_key').with(
        'type' => 'ssh-dss',
        'key'  => 'AAABBB',
        'user' => 'superman',
        'options' => ['permitopen="10.0.0.1:3306"'],
      )}

      it { should contain_file("/home/superman").with({
        'ensure'  => 'directory',
        'owner'   => 'superman',
        'group'   => 'superman',
        'mode'    => '0755'
      }) }
    end

    context 'deadpool account' do
      it { should contain_user('deadpool').with(
        'ensure' => 'absent',
      )}
    end
  end

  context 'manage GID of user\'s primary group' do
    let(:params){{
      :groups => { 'testgroup' => {
        'members' => [ 'www-data', 'testuser' ]
        }
      },
      :users => { 'testuser' => {
        'shell'   => '/bin/bash',
        'primary_group' => 'testgroup',
        'gid' => 800,
      }}
    }}

    it { should contain_user('testuser').with(
      'shell' => '/bin/bash',
    )}

    it { should contain_group('testgroup').with(
      'ensure' => 'present',
      'gid'    => 800,
    )}

  end

  context 'assign groups' do
    let(:params){{
      :users => { 'foo' => {
        'home' => '/home/foo',
        'groups' => ['users'],
      }}
    }}

    it { should contain_user('foo').with(
      'ensure' => 'present',
      'home' => '/home/foo'
    )}

    it { should contain_group('foo').with(
      'ensure' => 'present'
    )}
  end

  context 'allow changing primary group\'s name' do
    let(:params){{
      :users => { 'john' => {
        'primary_group' => 'users',
      }}
    }}

    it { should contain_user('john').with(
      'ensure' => 'present'
    )}

    it { should contain_group('users').with(
      'ensure' => 'present'
    )}

    it { should_not contain_group('john').with(
      'ensure' => 'present'
    )}
  end

  context 'optional group management' do
    let(:params){{
      :users => { 'mickey' => {
        'manage_group' => false,
      }}
    }}

    it { should_not contain_group('mickey').with(
      'ensure' => 'present'
    )}
  end

  context 'create new user' do
    let(:params){{
      :users => { 'foobar' => {
        'uid' => 1001,
        'gid' => 1001,
      }}
    }}

    it { should contain_user('foobar').with(
      'uid' => 1001,
      'gid' => 1001
    )}

    it { should contain_group('foobar').with(
      'gid'    => 1001,
      'ensure' => 'present'
    )}
  end

end