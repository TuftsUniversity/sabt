# IMPORTANT: if you delete this file your app will not work as
# expected.  you have been warned
use inc::Module::Install;

name 'TAPER';
all_from 'lib/TAPER.pm';

requires 'Catalyst::Runtime' => '5.7014';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Session::Store::File';
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Authentication::Store::LDAP';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Plugin::Cache';
requires 'Catalyst::Plugin::Cache::Store::Memory';
requires 'Catalyst::Plugin::Email';
requires 'Catalyst::Plugin::DateTime';
requires 'Catalyst::Model::DBIC::Schema';
requires 'DateTime::Format::MySQL';
requires 'SQL::Translator';
requires 'Config::Any' => '0.18';
requires 'HTML::FormFu' => '0.06000';
requires 'Catalyst::Controller::HTML::FormFu' => '0.06000';
requires 'DBIx::Class::Schema';
requires 'Moose';
requires 'Moose::Util::TypeConstraints';
requires 'Scalar::Util';
requires 'Set::Scalar';
requires 'Carp';
requires 'parent';
requires 'Config::General';
requires 'XML::LibXML';
requires 'Readonly';
requires 'File::Path';
requires 'File::Grep';
requires 'File::Copy';
requires 'Test::Pod';
requires 'Test::Pod::Coverage';
requires 'IO::Socket::SSL';
requires 'IO::String';
requires 'DBI';
requires 'DBD::mysql';
requires 'Archive::Zip';

catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
