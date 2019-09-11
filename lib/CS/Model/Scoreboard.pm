package CS::Model::Scoreboard;
use Mojo::Base 'MojoX::Model';

sub generate {
  my ($self, $round, $limit, $team_id) = @_;
  my $db = $self->app->pg->db;

  $round //= $db->query('select max(round) from scores')->array->[0];

  my $scoreboard = $db->query('
    select
      t.host, t.name, s1.n - s.n as d, s.*, s1.services as old_services, s1.score as old_score
    from scoreboard as s
    join teams as t on s.team_id = t.id
    join (
      select * from scoreboard where round = case when $1-1<0 then 0 else $1-1 end
    ) as s1 using (team_id)
    where s.round = $1 and ($3::int is null or s.team_id = $3) order by n limit $2', $round, $limit, $team_id)
    ->expand->hashes;

  my $services = $db->query('
    select s.id, name, active
    from service_activity_log as l join services as s on l.service_id = s.id
    where round = ?
  ', $round)->hashes->reduce(sub { $a->{$b->{id}} = {name => $b->{name}, active => $b->{active}}; $a }, {});

  return {scoreboard => $scoreboard->to_array, round => $round, services => $services};
}

sub generate_history {
  my ($self, $round) = @_;
  my $db = $self->app->pg->db;

  $round //= $db->query('select max(round) from scores')->array->[0];

  my $scoreboard = $db->query(q{
    with a as (
      select *, jsonb_array_elements(services) s
      from scoreboard where round <= $1
    ),
    b as (
      select round, team_id, max(score) score,
        json_agg(json_build_object('flags', s->'flags', 'sflags', s->'sflags', 'fp', s->'fp', 'status', s->'status') order by s->'id') services
      from a
      group by round, team_id
    )
    select round, json_agg(json_build_object('id', team_id, 'score', score, 'services', services)) scoreboard
    from b
    group by round order by round
  }, $round)->expand->hashes;

  return $scoreboard->to_array;
}

sub generate_for_team {
  my ($self, $team_id) = @_;
  my $db = $self->app->pg->db;

  my $round      = $db->query('select max(round) from scores')->array->[0];
  my $scoreboard = $db->query(
    q{
    select t.host, t.name, s.*
    from scoreboard as s
    join teams as t on s.team_id = t.id
    where team_id = $1 order by round desc
  }, $team_id
  )->expand->hashes;

  return {scoreboard => $scoreboard->to_array, round => $round};
}

1;
