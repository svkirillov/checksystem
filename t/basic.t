use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use CS::Command::manager;

BEGIN { $ENV{MOJO_CONFIG} = 'c_s_test.conf' }

my $t   = Test::Mojo->new('CS');
my $app = $t->app;
my $pg  = $app->pg;

$app->commands->run('reset_db');
$app->commands->run('ensure_db');

is $app->model('team')->id_by_address('127.0.2.213'),  2,     'right id';
is $app->model('team')->id_by_address('127.0.23.127'), undef, 'right id';

my $manager = CS::Command::manager->new(app => $app);
my $ids = $manager->start_round;
is $manager->round, 1, 'right round';
$app->minion->perform_jobs;
$manager->finalize_check($app->minion->job($_)) for @$ids;

# Runs
is $pg->db->query('select count(*) from runs')->array->[0], 8, 'right numbers of runs';

# Down
$pg->db->query('select * from runs where service_id = 1')->expand->hashes->map(
  sub {
    is $_->{round},  1,   'right round';
    is $_->{status}, 110, 'right status';
    like $_->{result}{check}{stderr},  qr/Oops/, 'right stderr';
    is $_->{result}{check}{stdout},    '',       'right stdout';
    is $_->{result}{check}{exception}, '',       'right exception';
    is $_->{result}{check}{timeout},   0,        'right timeout';
    is keys %{$_->{result}{put}},   0, 'right put';
    is keys %{$_->{result}{get_1}}, 0, 'right get_1';
    is keys %{$_->{result}{get_2}}, 0, 'right get_2';
  }
);

# Up
$pg->db->query('select * from runs where service_id = 2')->expand->hashes->map(
  sub {
    is $_->{round},  1,   'right round';
    is $_->{status}, 101, 'right status';
    for my $step (qw/check put get_1/) {
      is $_->{result}{$step}{stderr},    '',  'right stderr';
      is $_->{result}{$step}{stdout},    911, 'right stdout';
      is $_->{result}{$step}{exception}, '',  'right exception';
      is $_->{result}{$step}{timeout},   0,   'right timeout';
    }
    is keys %{$_->{result}{get_2}}, 0, 'right get_2';
  }
);

# Timeout
$pg->db->query('select * from runs where service_id = 4')->expand->hashes->map(
  sub {
    is $_->{round},  1,   'right round';
    is $_->{status}, 110, 'right status';
    is $_->{result}{check}{stderr},      '',           'right stderr';
    is $_->{result}{check}{stdout},      '',           'right stdout';
    like $_->{result}{check}{exception}, qr/timeout/i, 'right exception';
    is $_->{result}{check}{timeout},     1,            'right timeout';
    is keys %{$_->{result}{put}},   0, 'right put';
    is keys %{$_->{result}{get_1}}, 0, 'right get_1';
    is keys %{$_->{result}{get_2}}, 0, 'right get_2';
  }
);

# Flags
is $pg->db->query('select count(*) from flags')->array->[0], 2, 'right numbers of flags';
$pg->db->query('select * from flags')->hashes->map(
  sub {
    is $_->{round},  1,                'right round';
    is $_->{id},     911,              'right id';
    like $_->{data}, qr/[A-Z\d]{31}=/, 'right flag';
  }
);

my ($data, $flag_data);
$data = $app->model('flag')->accept(2, 'flag');
is $data->{ok}, 0, 'right status';
like $data->{error}, qr/no such flag/, 'right error';

$flag_data = $pg->db->query('select data from flags where team_id = 2 limit 1')->hash->{data};
$data = $app->model('flag')->accept(2, $flag_data);
is $data->{ok}, 0, 'right status';
like $data->{error}, qr/flag is your own/, 'right error';

$flag_data = $pg->db->query('select data from flags where team_id = 1 limit 1')->hash->{data};
$data = $app->model('flag')->accept(2, $flag_data);
is $data->{ok}, 1, 'right status';
is $pg->db->query('select data from stolen_flags where team_id = 2 and victim_team_id = 1 limit 1')
  ->hash->{data}, $flag_data, 'right flag';

$data = $app->model('flag')->accept(2, $flag_data);
is $data->{ok}, 0, 'right status';
like $data->{error}, qr/you already submitted this flag/, 'right error';

done_testing;
