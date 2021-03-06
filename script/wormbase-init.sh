#!/bin/bash

. /lib/lsb/init-functions

# Pull in our local environment variables
# Since wormbase.env isn't in our code repository,
# production servers won't have it; staging servers do.
# We keep our env file outside of the repository to
# so it doesn't have to be maintained across branches.
source /usr/local/wormbase/wormbase.env

# $ENV{APP} needs to be set during build.


# If the APP environment variable isn't set,
# assume we are running in production.
if [ ! $APP ]; then
    echo "   ---> APP is not defined; assuming a production deployment using wormbase_production.conf"
    export APP=production
#    export STARMAN_DEBUG=1

    # Application defaults
    export DAEMONIZE=true
    export PORT=5000
    export WORKERS=10
    export MAX_REQUESTS=500

    # The suffix for the configuration file to use.
    # This will take precedence over wormbase_local.conf
    # Primarily used to override the location of the user database.
    export CATALYST_CONFIG_LOCAL_SUFFIX=$APP

elif [ $APP == 'staging' ]; then
    echo "   ---> APP is set to staging: assuming we are host:staging.wormbase.org using wormbase_staging.conf"

    # reduce the number of workers.
    export DAEMONIZE=true
    export PORT=5000
    export WORKERS=5
    export MAX_REQUESTS=500

    # The suffix for the configuration file to use.
    # This will take precedence over wormbase_local.conf
    # Primarily used to override the location of the user database.
    export CATALYST_CONFIG_LOCAL_SUFFIX=$APP

elif [ $APP == 'qaqc' ]; then

    echo "   ---> APP is set to ${APP}: assuming we are host:qaqc.wormbase.org using wormbase_${APP}.conf"

    # reduce the number of workers.
    export DAEMONIZE=true
    export PORT=5000
    export WORKERS=8
    export MAX_REQUESTS=500

    # The suffix for the configuration file to use.
    # This will take precedence over wormbase_local.conf
    # Primarily used to override the location of the user database.
    export CATALYST_CONFIG_LOCAL_SUFFIX=$APP

else
    echo "   ---> APP is set to ${APP}: using wormbase_local.conf"

    # Assume these to all be set in the local environment

fi


# The absolute path to our installation.
CURR_DIR=`pwd`
export APP_HOME=$CURR_DIR
echo $APP_HOME

# Configure our GBrowse App
export GBROWSE_CONF=$ENV{APP_HOME}/conf/gbrowse
export GBROWSE_HTDOCS=$ENV{APP_HOME}/root/gbrowse

# GBrowse ONLY production sites
#    export MODULEBUILDRC="/usr/local/wormbase/extlib2/.modulebuildrc"
#    export PERL_MM_OPT="INSTALL_BASE=/usr/local/wormbase/extlib2"
#    export PERL5LIB="/usr/local/wormbase/extlib2/lib/perl5:/usr/local/wormbase/extlib2/lib/perl5/x86_64-linux-gnu-thread-multi"
#    export PATH="/usr/local/wormbase/extlib2/bin:$PATH"

export PERL5LIB=/usr/local/wormbase/extlib/lib/perl5:/usr/local/wormbase/extlib/lib/perl5/x86_64-linux-gnu-thread-multi:$ENV{APP_HOME}/lib:$PERL5LIB
export MODULEBUILDRC="/usr/local/wormbase/extlib/.modulebuildrc"
export PERL_MM_OPT="INSTALL_BASE=/usr/local/wormbase/extlib"
export PATH="/usr/local/wormbase/extlib/bin:$PATH"


# Fetch local defaults
PIDDIR=$APP_HOME/logs
PIDFILE=$PIDDIR/${APP}.pid
APPLIB=$APP_HOME/WormBase
APPDIR=$APP_HOME

if [ ! -d "$APP_HOME" ]; then
    echo "\$APP_HOME does not exist"
    exit 1
fi

if [ ! $WORKERS ]; then
    echo "\$WORKERS is not defined"
    exit 1
fi

if [ ! $PORT ]; then
    echo "\$PORT is not defined"
    exit 1
fi

if [ ! $MAX_REQUESTS ]; then
    MAX_REQUESTS=1000
fi



# Which starman are we running?
STARMAN=`which starman`
STARMAN_OPTS="-I$APPDIR/lib --access-log $APPDIR/logs/starman_access.log --error-log $APPDIR/logs/starman_error.log --workers $WORKERS --pid $PIDFILE --port $PORT --max-request $MAX_REQUESTS --daemonize $APPDIR/wormbase.psgi"


check_running() {
    [ -s $PIDFILE ] && kill -0 $(cat $PIDFILE) >/dev/null 2>&1
}

check_compile() {
  if ( cd $APPDIR ; perl -Ilib -M$APPLIB -ce1 ) ; then
    return 1
  else
    return 0
  fi
}

_start() {

    echo "Launching WormBase app with the following parameters..."
    echo "     appdir  : $APP_HOME"
    echo "     pidfile : $PIDFILE"
    echo "     workers : $WORKERS"
    echo "    max_reqs : $MAX_REQUESTS"
    echo "        port : $PORT"

#  /sbin/start-stop-daemon --start --pidfile $PIDFILE \
#  --chdir $APP_HOME --startas $STARMAN "$STARMAN_OPTS"

#  /sbin/start-stop-daemon --start --pidfile $PIDFILE \
#  --chdir $APP_HOME --exec $STARMAN -- "$STARMAN_OPTS"

    if [ $DAEMONIZE ]; then
	/sbin/start-stop-daemon --start --pidfile $PIDFILE \
	    --chdir $APP_HOME --exec $STARMAN -- -I$APP_HOME/lib --workers $WORKERS --pid $PIDFILE --port $PORT --max-request $MAX_REQUESTS --daemonize $APP_HOME/wormbase.psgi
#	    --chdir $APP_HOME --exec $STARMAN -- -I$APP_HOME/lib --workers $WORKERS --pid $PIDFILE --port $PORT --max-request $MAX_REQUESTS --daemonize $APP_HOME/wormbase.psgi



    else
	/sbin/start-stop-daemon --start --pidfile $PIDFILE \
	    --chdir $APP_HOME --exec $STARMAN -- -I$APP_HOME/lib --workers $WORKERS --pid $PIDFILE --port $PORT --max-request $MAX_REQUESTS  $APP_HOME/wormbase.psgi
    fi

    echo ""
    echo "   Attempting to start..."

    for i in 1 2 3 4 ; do
	sleep 1
	if check_running ; then
	    echo "     WormBase app is now starting up..."
	    return 0
	fi
    done

  # Try again if we've failed.
    echo "   Failed. Trying again..."
    if [ $DAEMONIZE ]; then
	/sbin/start-stop-daemon --start --pidfile $PIDFILE \
	    --chdir $APP_HOME --exec $STARMAN -- -I$APP_HOME/lib --workers $WORKERS --pid $PIDFILE --port $PORT --max-request $MAX_REQUESTS --daemonize $APP_HOME/wormbase.psgi
    else
	/sbin/start-stop-daemon --start --pidfile $PIDFILE \
	    --chdir $APP_HOME --exec $STARMAN -- -I$APP_HOME/lib --workers $WORKERS --pid $PIDFILE --port $PORT --max-request $MAX_REQUESTS  $APP_HOME/wormbase.psgi
    fi

    for i in 1 2 3 4 ; do
	sleep 1
	if check_running ; then
	    echo "     $APP is now starting up"
	    return 0
	fi
    done

    return 1
}

start() {
    #log_daemon_msg "Starting $APP" $STARMAN
    echo ""

    if check_running; then
        log_progress_msg "already running"
        log_end_msg 0
        exit 0
    fi

    rm -f $PIDFILE 2>/dev/null

    _start
    log_end_msg $?
    return $?
}

stop() {
    log_daemon_msg "Stopping $APP" $STARMAN
    echo ""

    /sbin/start-stop-daemon --stop --oknodo --pidfile $PIDFILE
    sleep 3
    log_end_msg $?
    return $?
}

restart() {
    log_daemon_msg "Restarting $APP" $STARMAN
    echo ""

    if check_compile ; then
        log_failure_msg "Error detected; not restarting."
        log_end_msg 1
        exit 1
    fi

    /sbin/start-stop-daemon --stop --oknodo --pidfile $PIDFILE
    _start
    log_end_msg $?
    return $?
}


# See how we were called.
case "$1" in
    start)
        start
    ;;
    stop)
        stop
    ;;
    restart|force-reload)
        restart
    ;;
    *)
        echo $"Usage: $0 {start|stop|restart}"
        exit 1
esac
exit $?
