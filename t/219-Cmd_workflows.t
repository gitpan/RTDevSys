use strict;
use warnings;

use Test::More tests => 1;
use RTDevSys::Test;

BEGIN{ use_ok('RTDevSys::Cmd::Command::workflows'); }

__END__

package RTDevSys::Cmd::Command::workflows;
use strict;
use warnings;
use RTDevSys;
use RTDevSys::Util;

use Moose;
extends qw(MooseX::App::Cmd::Command);

with 'RTDevSys::Cmd::Roles::Standard';

sub abstract { "Installs workflows and runs workflow migrations" }

sub usage_desc {
  my ($self) = @_;
  my ($command) = $self->command_names;
  return "%c $command %o [WORKFLOW NAMES]";
}

sub run {
    my ($self, $opt, $args) = @_;
    my @workflows = @$args;
    @workflows = @{ workflow_list() } unless ( @workflows );
    require RTDevSys::Workflows;
    for my $item ( @workflows ) {
        RTDevSys::Workflows::initialize_workflow( $item );
        RTDevSys::Workflows::run_migrations( 'workflow', $item )
    }
}

add_deploy_task (
    'workflows',
    sub {
        require RTDevSys::Workflows;
        for my $item ( @{ workflow_list() }) {
            RTDevSys::Workflows::initialize_workflow( $item );
            RTDevSys::Workflows::run_migrations( 'workflow', $item )
        }
    },
    depends => [ 'plugins' ],
);

1;
