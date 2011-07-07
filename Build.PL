use Module::Build;
use strict;
use warnings;

my $build = Module::Build->new(
	module_name => 'Array::Tour',
	dist_author => 'John M. Gamble <jgamble@cpan.org>',
	dist_version_from => 'lib/Array/Tour.pm',  

	requires => { 'perl' => '5.8.0' },
	build_requires => { 'Test::Simple' => 0 },

	include_dirs => [ '.' ],
	license => 'perl',
	create_readme => 0,
	create_license => 1,
	create_makefile_pl => 'traditional',
	meta_merge => {
	       resources => {
			repository => 'http://github.com/jgamble/Array-Tour/'
	       }
       }
);

$build->create_build_script;

