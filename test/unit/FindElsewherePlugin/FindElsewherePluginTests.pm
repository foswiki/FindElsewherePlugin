use strict;

package FindElsewherePluginTests;

use FoswikiFnTestCase;
our @ISA = qw( FoswikiFnTestCase );

#use base qw(FoswikiTestCase);

use strict;

#use Foswiki::UI::Save;
use Error qw( :try );
use Foswiki::Plugins;
use Foswiki::Plugins::FindElsewherePlugin;

my $expected;
my $source;

#my $foswiki;

sub new {
    my $self = shift()->SUPER::new( 'ControlWikWordPluginFunctions', @_ );
    return $self;
}

sub setLocalSite {
    $Foswiki::cfg{Plugins}{FindElsewherePlugin}{Enabled} = 1;
    $Foswiki::cfg{Plugins}{FindElsewherePlugin}{Module} =
      'Foswiki::Plugins::FindElsewherePlugin';
}

sub loadExtraConfig {
    my $this = shift;
    $this->SUPER::loadExtraConfig();
    setLocalSite();
}

sub set_up {
    my $this = shift;

    $this->SUPER::set_up();

    my $query;
    eval {
        require Unit::Request;
        require Unit::Response;
        $query = new Unit::Request("");
    };
    if ($@) {
        $query = new CGI("");
    }
    $query->path_info( "/" . $this->{test_web} . "/TestTopic" );
    $this->{session}->finish() if ( defined( $this->{session} ) );
    $this->{session} = new Foswiki( undef, $query );
    $Foswiki::Plugins::SESSION = $this->{session};

    $Foswiki::cfg{LocalSitePreferences} = "$this->{users_web}.SitePreferences";

    Foswiki::Func::saveTopic( $this->{users_web}, 'ProjectContributor', undef, "Some text" );

    Foswiki::Func::setPreferencesValue( 'CONTROLWIKIWORDPLUGIN_DEBUG', '1' );
}

sub doTest {
    my ( $this, $source, $expected, $assertFalse ) = @_;

    _trimSpaces($source);
    _trimSpaces($expected);

    #print " SOURCE = $source  EXPECTED = $expected \n";

    Foswiki::Plugins::FindElsewherePlugin::initPlugin( "TestTopic",
        $this->{test_web}, "MyUser", "System" );
    Foswiki::Plugins::FindElsewherePlugin::startRenderingHandler( $source,
        $this->{test_web} );

    #print " RENDERED = $source \n";
    if ($assertFalse) {
        $this->assert_str_not_equals( $expected, $source );
    }
    else {
        $this->assert_str_equals( $expected, $source );
    }
}

=pod

---++ Multiple web linking

=cut

# ########################################################
# Verify that a topic is properly found in multiple webs
# ########################################################
sub test_MultiWebTopic {
    my $this = shift;

    Foswiki::Func::setPreferencesValue(
        'LOOKELSEWHEREWEBS', "$this->{users_web}, System" );
    Foswiki::Func::setPreferencesValue( 'NOAUTOLINK', '0' );

    $source = <<END_SOURCE;
Test ProjectContributor Word
END_SOURCE

    $expected = <<"END_EXPECTED";
Test <nop/>ProjectContributor<sup>([[$this->{users_web}.ProjectContributor][$this->{users_web}]],[[System.ProjectContributor][System]])</sup> Word
END_EXPECTED

    $this->doTest( $source, $expected, 0 );

}

=pod

---++ Multiple web linking with macro webnames

=cut

# ########################################################
# Verify that a topic is properly found in multiple webs
# Item10460: Webs identified by macro - %USERSWEB% and %SYSTEMWEB%
# ########################################################
sub test_MultiWebTopicMacros {
    my $this = shift;

    Foswiki::Func::setPreferencesValue(
        'LOOKELSEWHEREWEBS', '%USERSWEB%, %SYSTEMWEB%' );
    Foswiki::Func::setPreferencesValue( 'NOAUTOLINK', '0' );

    $source = <<END_SOURCE;
Test ProjectContributor Word
END_SOURCE

    $expected = <<"END_EXPECTED";
Test <nop/>ProjectContributor<sup>([[$this->{users_web}.ProjectContributor][$this->{users_web}]],[[System.ProjectContributor][System]])</sup> Word
END_EXPECTED

    $this->doTest( $source, $expected, 0 );

}

=pod

---++ Email address with WikiWord on left

=cut

# ########################################################
# Item11199: WikiWords linked incorrectly in email addresses
# ########################################################
sub test_WikiWordAsEmailAddress {
    my $this = shift;

    Foswiki::Func::setPreferencesValue(
        'LOOKELSEWHEREWEBS', '%USERSWEB%, %SYSTEMWEB%' );
    Foswiki::Func::setPreferencesValue( 'NOAUTOLINK', '0' );

    $source = <<'END_SOURCE';
Test ProjectContributor@example.com Word
END_SOURCE

    $expected = <<'END_EXPECTED';
Test ProjectContributor@example.com Word
END_EXPECTED

    $this->doTest( $source, $expected, 0 );

}



# ####################
# Utility Functions ##
# ####################

sub _trimSpaces {

    #my $text = $_[0]

    $_[0] =~ s/^[[:space:]]+//s;    # trim at start
    $_[0] =~ s/[[:space:]]+$//s;    # trim at end
}

1;
