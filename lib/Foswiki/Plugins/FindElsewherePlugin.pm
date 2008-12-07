# Copyright (C) 2002 Mike Barton, Marco Carnut, Peter HErnst
#	(C) 2003 Martin Cleaver, (C) 2004 Matt Wilkie (C) 2007 Crawford Currie
#   (C) 2008 Foswiki Contributors
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details, published at 
# http://www.gnu.org/copyleft/gpl.html
#
# =========================
#
# This is the FindElsewhere Foswiki plugin,
# see http://foswiki.org/Extensions/FindElsewherePlugin for details.

package Foswiki::Plugins::FindElsewherePlugin;

use strict;

use vars qw(
            $VERSION $RELEASE $NO_PREFS_IN_TOPIC $disabled
           );

$NO_PREFS_IN_TOPIC = 1;

$RELEASE = '$Date: 2007-09-26 04:16:46 +1000 (Wed, 26 Sep 2007) $';
$VERSION = '$Rev: 15055 $';

sub initPlugin {
    #my( $topic, $web, $user, $installWeb ) = @_;

    # check for Plugins.pm versions
    if( $Foswiki::Plugins::VERSION < 1 ) {
        Foswiki::Func::writeWarning( "Version mismatch between FindElsewherePlugin and Plugins.pm" );
        return 0;
    }

    $disabled =
      Foswiki::Func::getPreferencesFlag( "DISABLELOOKELSEWHERE" );
    unless( defined( $disabled )) {
        # Compatibility, deprecated
        $disabled =
          Foswiki::Func::getPluginPreferencesFlag( "DISABLELOOKELSEWHERE" );
    }

    return !$disabled;
}

sub startRenderingHandler {
    # This handler is called by getRenderedVersion just before the line loop
    ### my ( $text, $web ) = @_;
    return if $disabled;

    require Foswiki::Plugins::FindElsewherePlugin::Core;

    return Foswiki::Plugins::FindElsewherePlugin::Core::handle(@_);
}

1;
