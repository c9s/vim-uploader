package VIM::Uploader;
use WWW::Mechanize;
use File::Spec;
use warnings;
use strict;

=head1 NAME

VIM::Uploader - upload your vim script to vim.org

=head1 VERSION

0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use VIM::Uploader;

    my $uploader = VIM::Uploader->new();

    $uploader->login( )

or 

    $uploader->login( 
        user => 'xxx',
        pass => 'xxx',
    );


    my $ok = $uploader->upload( 
        script_id => 1234,
        script_file => '/path/to/your/file',
        vim_version => '7.0',               # valid values:  7.0 , 6.0 , 5.7
        script_version => '0.2',            # your vim script version
        version_comment => 'release note'   # your vim script release note.
    );

    print "DONE" if $ok;

=head1 FUNCTIONS

=cut

sub new {
    my $self = bless {} , shift;
    my %args = @_;
    $self->{mech} = WWW::Mechanize->new();
    $|++;
    return $self;
}

sub mech {
    my $self = shift;
    return $self->{mech};
}


sub config_file  { File::Spec->join($ENV{HOME},".vim-uploader") }

sub read_config {
    my $path = config_file();
    return unless -e $path;

    open FH , "<" , $path;
    my $line = <FH>;
    chomp $line;
    my ($user,$pass) = split /:/,$line;
    close FH;

    return {
        user => $user,
        pass => $pass,
    };
}

sub login {
    my $self = shift;
    my $config;
    $config = { @_ } if @_;
    $config ||= $self->read_config();

    unless( $config ) {
        print "Seems you dont have " . config_file() . ". create one ? (Y/n) : ";
        my $ans = <STDIN>;
        chomp $ans;
        $ans ||= 'Y';
        if( $ans =~ /y/i ) {
            print "User: ";
            my $user = <STDIN>;
            chomp $user;
            
            print "Password: ";
            my $pass = <STDIN>;

            open FH , ">" , config_file();
            print FH "$user:$pass\n";
            close FH;

            print "Created.\n";
            $config = $self->read_config();
        }
    }

    print "Login\n";
    $self->mech->get( "http://www.vim.org/login.php" );
    $self->mech->form_name( 'login' );
    $self->mech->field( userName => $config->{user} );
    $self->mech->field( password => $config->{pass} );
    $self->mech->click_button( value => 'Login');

    die "Authentication Failed" 
        if $self->mech->content =~ /Authentication failed/;

    print "Sucessed\n";

}


sub upload {
    my $self = shift;
    my %args = @_;
    my $script_id = $args{ script_id };

    my $new_version_url
        = sprintf(
        'http://www.vim.org/scripts/add_script_version.php?script_id=%d',
        $script_id );

    print "Reading upload form\n";

    $self->mech->get( $new_version_url );

    die "ERROR" if $self->mech->content =~ /Vim Online Error/;

    $self->mech->form_name( 'script' );
    for ( keys %args ) {
        $self->mech->field( $_ => $args{$_} );
    }

    $self->mech->click_button( value => 'upload');

    die "ERROR" if $self->mech->content =~ /Vim Online Error/;

    print "DONE\n";

    $self->mech->get( 'http://www.vim.org/scripts/script.php?script_id=' . $script_id );

    my $html = $self->mech->content;
    return index($html, $args{version_comment});
}

=head1 AUTHOR

Cornelius, C<< <cornelius.howl at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-vim-uploader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=VIM-Uploader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc VIM::Uploader


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=VIM-Uploader>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/VIM-Uploader>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/VIM-Uploader>

=item * Search CPAN

L<http://search.cpan.org/dist/VIM-Uploader/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Cornelius.

This program is released under the following license: MIT


=cut

1; # End of VIM::Uploader
