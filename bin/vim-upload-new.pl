#!/usr/bin/env perl
use VIM::Uploader;
use File::Temp 'tempfile';
my ($fh, $filename) = tempfile();

open FH, ">" , $filename;

print FH <<END;
script_name:

    [script name]

script_file:

    [filepath]

script_type:

    ['color scheme' , 'ftplugin' , 'game' , 'indent' , 'syntax' , 'utility' , 'patch']

vim_version:

    [5.7 , 6.0 , 7.0 , 7.2]

script_version: 

    [version]

summary:

    [summary]

description:

    [description]

install_details:

    [install details]
END
close FH;

system( qq(vim $filename) );

open FH , "<" , $filename;
local $/;
my $content = <FH>;
close FH;

# print $content;


# parse content
my @lines = split /\n/,$content;

my $section;
my %parts;
my @buffer;

sub flush_buffer {
    my ($section) = @_;
    if( @buffer and $section ) {
        $parts{ $section } = join "\n", @buffer;
        @buffer = ( );
    }
}

for my $l ( @lines ) {
    if ( $l =~ m{^(\w+):\s*$} ) {
        flush_buffer( $section );
        $section = $1;
        next;
    }
    else {
        push @buffer,$l;
    }
}
flush_buffer( $section );

# oneline arguments
for ( qw(script_name script_file script_type vim_version script_version) ) {
    $parts{ $_ } =~ s{\n}{}g;
    $parts{ $_ } =~ s{^\s*}{}g;
    $parts{ $_ } =~ s{\s*$}{}g;
}

$parts{ script_name } =~ s{\s}{-}g;

my $uploader = VIM::Uploader->new();
$uploader->login();
$uploader->upload_new( %parts );
print "Done";
