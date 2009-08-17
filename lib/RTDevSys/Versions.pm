package RTDevSys::Versions;

#{{{

=pod

=head1 NAME

RTDevSys::Versions

=head1 EARLY VERSION WARNING

This is a very early version of RTDevSys. It is ready for use, and in fact is
being used. However there may be some API changes in the future. As well there
may be some missing, incomplete, or untested features. At the moment the
database commands only support postgres not mysql.

=cut

#}}}

use strict;
use warnings;
use YAML::Syck;
use MooseX::ClassAttribute;
use RTDevSys::Util;
use RTDevSys;

use base 'Exporter';
our @EXPORT = qw/ item_version item_disabled stable_version demo_version
indicated_version can_install_plugin can_install_workflow can_install_system /;

class_has VERSIONS => (
    is => 'rw',
    isa => 'HashRef',
    lazy => 1,
    default => sub { LoadFile( RTDevSys->VERSIONS_FILE() )},
);

#{{{ Functions for checking versions.yaml
#{{{ item_version()
sub item_version {
    my ( $component, $item ) = @_;
    $item = strip_lead( $item );
    return VERSIONS()->{ $component }->{ $item };
}
#}}}
#{{{ item_disabled()
sub item_disabled {
    my ( $component, $item ) = @_;
    $item = strip_lead( $item );
    my $data = item_version( @_ );
    return 1 unless $data;
    return 1 if $data->{ disable };
    return 0 if ( $data->{ devel } and ( RTDevSys->BUILD eq 'devel' or not RTDevSys->BUILD ));
    return 1 unless defined( stable_version( @_ )) || defined( demo_version( @_ ));
    return 0;
}
#}}}
#{{{ stable_version()
sub stable_version {
    my ( $component, $item ) = @_;
    $item = strip_lead( $item );
    my $data = item_version( @_ );
    return $data->{ stable };
}
#}}}
#{{{ demo_version()
sub demo_version {
    my ( $component, $item ) = @_;
    $item = strip_lead( $item );
    my $data = item_version( @_ );
    return $data->{ demo } || stable_version( @_ );
}
#}}}
#{{{ indicated_version()
sub indicated_version {
    return stable_version( @_ ) if RTDevSys->BUILD eq 'stable';
    return demo_version( @_ ) if RTDevSys->BUILD eq 'demo';
    die("Unhandled condition, specified version is neither stable nor demo! [" . RTDevSys->BUILD . "]\n");
}
#}}}
#{{{ can_install_plugin()
sub can_install_plugin {
    my ( $plugin ) = @_;
    return 0 if item_disabled( 'plugin', $plugin );
    return 1 if RTDevSys->BUILD eq 'devel';
    return indicated_version( 'plugin', $plugin );
}
#}}}
#{{{ _can_install_workflow()
sub _can_install_workflow {
    my ( $component, $workflow, $version ) = @_;
    die( "no workflow specified!\n" ) unless $workflow;
    $version ||= 0;
    return 0 if item_disabled( $component, $workflow );
    return 1 if RTDevSys->BUILD eq 'devel';
    my $max_version = indicated_version( $component, $workflow );
    return 0 if (not defined( $max_version )) or $version > $max_version;
    return 1;
}
#}}}
#{{{ can_install_workflow()
sub can_install_workflow {
    return _can_install_workflow( 'workflow', @_ );
}
#}}}
#{{{ can_install_system()
sub can_install_system {
    return _can_install_workflow( 'system', 'db_version', @_ );
}
#}}}
#}}}

1;

__END__

=head1 AUTHORS

Chad Granum E<lt>chad@opensourcery.comE<gt>

=head1 COPYRIGHT

Copyright 2009 OpenSourcery, LLC.

This file is part of RTDevSys

RTDevSys is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

RTDevSys is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with RTDevSys.  If not, see <http://www.gnu.org/licenses/>.

=cut

