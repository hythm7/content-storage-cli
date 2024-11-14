#!/usr/bin/env raku 

use Config;
use JSON::Fast;
use Prettier::Table;
use Cro::HTTP::Client;

my %*SUB-MAIN-OPTS = :named-anywhere, :allow-no;

my enum Status  <✓ ✗ ⚪ ⚠>;


my class Config::Parser::JSON is Config::Parser {

  method read( Str $path --> Hash) {
    from-json( slurp($path) );
  }

  method write( IO::Path:D( Str ) $path, Hash $config --> Bool ) {
    $path.spurt( to-json $config );
    True;
  }
}

my $config-file = $*HOME.add( '.content-storage-cli' ).add( 'config.json' );

my $config = Config.new(

  {
    storage => {
      name => Str,
      api => {
        uri => Str,
        page    => UInt,
        limit   => UInt,
      },
    },
    verbose => Bool,
    session => {
      userid    => "",
      sessionid => "",
    },
  },
);


$config.=read: $config-file, Config::Parser::JSON;

my $api-base-uri = Cro::Uri::HTTP.parse: $config<storage><api><uri>;

my $api-page  =  $config<storage><api><page>;
my $limit     =  $config<storage><api><limit>;

my $user    =  $config<session><userid>;
my $session =  $config<session><sessionid>;


my $verbose  =  $config<verbose>;


my subset UUID of Str where /^
  <[0..9 a..f A..F]> ** 8 "-"
  [ <[0..9 a..f A..F]> ** 4 "-" ] ** 2
  <[8 9 a b A B]><[0..9 a..f A..F]> ** 3 "-"
  <[0..9 a..f A..F]> ** 12
$/;

# TODO: use better regex
my subset Identity of Str where / ^ [ <-[ : ]>* ]+ %% ":" $ /;

my subset ID where any( UUID, Identity );

enum Keyword  <distributions distribution builds build users user my get search add meta update password download log delete register login logout>;

proto sub MAIN ( Keyword, | ) is export {

  CATCH {

    when X::Cro::HTTP::Error {

      my %body = await .response.body;

      if %body {
        http-error |%body;
      } else {
        note .message;
      }
    }

    default { say .message }
  }

  {*}
}


multi sub MAIN (

  distributions,

  UInt:D :$page    = $api-page,

) {

  my $uri =  $api-base-uri.add: $api-base-uri ~ distributions;

  my $response = await Cro::HTTP::Client.get: $uri.add-query( :$page, :$limit ), cookies => { :$session };

  my @distribution = await $response.body;

  my @data = @distribution;

  my @field-names = $verbose ?? <Identity Name Version Auth Api Created> !! 'Identity';

  my $table = create-table :@data, :title<Distributions>, :sort-by<Identity>, :@field-names;

  say $table;

}

multi sub MAIN (

  builds,

  UInt:D :$page    = $api-page,

) {

  my $uri =  $api-base-uri.add: $api-base-uri ~ builds;

  my $response = await Cro::HTTP::Client.get: $uri.add-query( :$page, :$limit ), cookies => { :$session };

  my @build = await $response.body;

  my @data = @build.map( -> %build {

    %build<status> = Status( %build<status> );
    %build<meta>   = Status( %build<meta> );
    %build<test>   = Status( %build<test> );

    %build;

  } );


  my @field-names = $verbose ?? <Status User Identity Meta Test Started Completed Id> !! <Status User Id>;

  my $table = create-table :@data, :title<Builds>, :sort-by<User>, :@field-names;

  say $table;

}


multi sub MAIN (

  users,

  UInt:D :$page    = $api-page,

) {

  my $uri =  $api-base-uri.add: $api-base-uri ~ users;

  my $response = await Cro::HTTP::Client.get: $uri.add-query( :$page, :$limit ), cookies => { :$session };

  my @user = await $response.body;

  my @data = @user.map( -> %user {

    %user<admin>   =  %user<admin> ?? '✓' !! '';

    %user;

  } );

  my @field-names = $verbose ?? <Username FirstName LastName  Email Admin Created> !! <Username Admin Created>;

  my $table = create-table :@data, :title<Users>, :sort-by<Username>, :@field-names;

  say $table;

}


multi sub MAIN (

  my,
  distributions,

  UInt:D :$page    = $api-page,

) {

  return say 'Please login first!' unless $user;

  my $uri =  $api-base-uri.add: users ~ "/$user/" ~ distributions;

  my $response = await Cro::HTTP::Client.get: $uri.add-query( :$page, :$limit ), cookies => { :$session };

  my @distribution = await $response.body;

  my @data = @distribution;

  my @field-names = $verbose ?? <Identity Name Version Auth Api Created> !! 'Identity';

  my $table = create-table :@data, :title<Distributions>, :sort-by<Identity>, :@field-names;

  say $table;

}

multi sub MAIN (

  my,
  builds,

  UInt:D :$page    = $api-page,

) {


  return say 'Please login first!' unless $user;

  my $uri =  $api-base-uri.add: users ~ "/$user/" ~ builds;

  my $response = await Cro::HTTP::Client.get: $uri.add-query( :$page, :$limit ), cookies => { :$session };

  my @build = await $response.body;

  my @data = @build.map( -> %build {

    %build<status> = Status( %build<status> );
    %build<meta>   = Status( %build<meta> );
    %build<test>   = Status( %build<test> );

    %build;

  } );


  my @field-names = $verbose ?? <Status User Identity Meta Test Started Completed Id> !! <Status User Id>;

  my $table = create-table :@data, :title<Builds>, :sort-by<User>, :@field-names;

  say $table;

}


multi sub MAIN (

  search,
  distributions,

  Str:D   $name,

  UInt:D :$page    = $api-page,

) {

  my $uri =  $api-base-uri.add( ~distributions );

  my $response = await Cro::HTTP::Client.get: $uri.add-query( :$name, :$page, :$limit ), cookies => { :$session };

  my @distribution = await $response.body;

  my @data = @distribution;

  my @field-names = $verbose ?? <Identity Name Version Auth Api Created> !! 'Identity';

  my $table = create-table :@data, :title<Distributions>, :sort-by<Identity>, :@field-names;

  say $table;


}

multi sub MAIN (

  search,
  builds,

  Str:D   $name,

  UInt:D :$page    = $api-page,

) {

  my $uri =  $api-base-uri.add( ~builds );

  my $response = await Cro::HTTP::Client.get: $uri.add-query( :$name, :$page, :$limit ), cookies => { :$session };


  my @build = await $response.body;

  my @data = @build.map( -> %build {

    %build<status> = Status( %build<status> );
    %build<meta>   = Status( %build<meta> );
    %build<test>   = Status( %build<test> );

    %build;

  } );


  my @field-names = $verbose ?? <Status User Identity Meta Test Started Completed Id> !! <Status User Id>;

  my $table = create-table :@data, :title<Builds>, :sort-by<User>, :@field-names;

  say $table;

}

multi sub MAIN (

  search,
  users,

  Str:D   $name,

  UInt:D :$page    = $api-page,

) {

  my $uri =  $api-base-uri.add( ~users );

  my $response = await Cro::HTTP::Client.get: $uri.add-query( :$name, :$page, :$limit ), cookies => { :$session };

  my @user = await $response.body;

  my @data = @user.map( -> %user {

    %user<admin>   =  %user<admin> ?? '✓' !! '';

    %user;

  } );

  my @field-names = $verbose ?? <Username FirstName LastName  Email Admin Created> !! <Username Admin Created>;

  my $table = create-table :@data, :title<Users>, :sort-by<Username>, :@field-names;

  say $table;

}

multi sub MAIN (

  my,
  user,

) {


  return say 'Please login first!' unless $user;

  my $uri =  $api-base-uri.add: users ~ "/$user";

  my $response = await Cro::HTTP::Client.get: $uri, cookies => { :$session };

  my %user = await $response.body;

  %user<admin>   =  %user<admin> ?? '✓' !! '';

  my @data = %user.item;

  my @field-names = $verbose ?? <Username FirstName LastName  Email Admin Created> !! <Username Admin Created>;

  my $table = create-table :@data, :title<Users>, :sort-by<Username>, :@field-names;

  say $table;

}


multi sub MAIN (

  delete,
  distribution,

  ID:D    $distribution,

) {

  my $uri =  $api-base-uri.add( ~distributions );

  await Cro::HTTP::Client.delete: $uri.add-query( :$distribution ), cookies => { :$session };

}

multi sub MAIN (

  delete,
  build,

  UUID:D  $build,

) {

  my $uri =  $api-base-uri.add( ~builds );

  await Cro::HTTP::Client.delete: $uri.add-query( :$build ), cookies => { :$session };

}

multi sub MAIN (

  delete,
  user,

  Str:D   $user,

) {

  my $uri =  $api-base-uri.add( ~users );

  await Cro::HTTP::Client.delete: $uri.add-query( :$user ), cookies => { :$session };

}

multi sub MAIN (

  build,
  log,

  UUID:D   $build,

) {

  my $uri =  $api-base-uri.add: builds ~ "/$build/" ~ log;

  my $response = await Cro::HTTP::Client.get: $uri, cookies => { :$session };

  my %build = await $response.body;

  say %build<log>;

}

multi sub MAIN (

  update,
  user,

  ID:D $user,

  Str:D :$password,

) {

  my $uri =  $api-base-uri.add: users ~ "/$user/password";

  my $response = await Cro::HTTP::Client.put: $uri,
  :content-type<application/x-www-form-urlencoded>,
  body => [ :$password ],
  cookies => { :$session };

}


multi sub MAIN (

  update,
  user,

  ID:D $user,

  Bool:D :$admin,

) {

  my $uri =  $api-base-uri.add: users ~ "/$user/admin";

  my $response = await Cro::HTTP::Client.put: $uri,
  :content-type<application/x-www-form-urlencoded>,
  body => [ admin => $admin.Int ],
  cookies => { :$session };

}

multi sub MAIN (

  update,
  my,
  password,

  Str:D $password,

) {

  samewith( update, user, $user, :$password );

}


multi sub MAIN (

  download,

  Identity:D   $identity,

) {

  my $uri = $api-base-uri.add( "/archives/$identity" );

  my $body = await Cro::HTTP::Client.get-body: $uri, cookies => { :$session };

  my IO::Path:D $archive = $*TMPDIR.add: $identity;

  $archive.spurt: $body;

  say ~$archive;

}

multi sub MAIN (

  add,

  IO::Path:D( Str ) $archive,

) {


  use EventSource::Client;

  my $source =  ~$api-base-uri.add( "/server-sent-events" );

  my $uri =  $api-base-uri.add( ~builds );

  my $response = await Cro::HTTP::Client.post: $uri,
    :content-type<multipart/form-data>,
    body => [
      Cro::HTTP::Body::MultiPartFormData::Part.new(
        :name<file>,
        headers => [Cro::HTTP::Header.new(
          name => 'Content-type',
          value => 'application/tar+gzip'
        )],
        body-blob => slurp( $archive, :bin)
      )
    ],
    cookies => { :$session };


  my %body = await $response.body;


  my $id = %body<id>;

  say "Building: ｢$id｣";

  react {

    whenever EventSource::Client.new( :$source ) -> $event {

      my %data = from-json $event.data;

      if $event.type eq $id {

        say %data<log>;

      }
      elsif ( $event.type eq 'message' ) and ( %data<ID> eq $id ) {
        done if Status( %data<build><status> ) ~~ any <✓ ✗>;
      }

    }
  }
}

multi sub MAIN (

  login,

  Str:D $username,
  Str:D $password,

) {

  my $uri =  $api-base-uri.add: "auth/login";

  my $response = await Cro::HTTP::Client.post: $uri,
  :content-type<application/x-www-form-urlencoded>,
  body => [ :$username, :$password ];

  if $response.status == 200 {

    my $body = await $response.body;

    my $userid = $body.<id>;

    $session = $response.cookies.first( *.name eq 'session' ).value;

    $config<session><userid> = $userid;
    $config<session><sessionid>       = $session;

    $config.write: $config-file, Config::Parser::JSON;

  } else {
    note $response.status;
  }

}

multi sub MAIN (

  register,

  Str:D $username,
  Str:D $password,

  Str:D :$firstname = "",
  Str:D :$lastname  = "",
  Str:D :$email     = "",

) {

  my $uri =  $api-base-uri.add: "auth/register";

  my $response = await Cro::HTTP::Client.post: $uri,
  :content-type<application/x-www-form-urlencoded>,
  body => [ :$username, :$firstname, :$lastname, :$email, :$password ];

  if $response.status == 200 {

    my $body = await $response.body;

    my $userid = $body.<id>;

  } else {
    note $response.status;
  }

}

multi sub MAIN (

  logout,

) {

 await Cro::HTTP::Client.get: $api-base-uri ~ 'auth/logout', cookies => { :$session };

}

my sub create-table ( Str:D :$title!, Str:D :$sort-by!, :@field-names!, :@data!  --> Prettier::Table:D ) {

  my $table = Prettier::Table.new: :$title, :$sort-by, :@field-names, :align<l>;

  @data.map( { $table.add-row: @field-names.map( -> $field { .{ $field.lc } } ) } );

  $table;

}


my sub http-error ( Int:D :$code!, Str:D :$message! ) { note "Error: $code: $message" }
