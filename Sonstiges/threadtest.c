#include <stdio.h>
#include <pthread.h>
#include <errno.h>
#include <sys/time.h>

struct _info
{
	pthread_mutex_t mutex;
	pthread_cond_t condition;
} typedef info;



void subthread(info *myinfo);

main()
{
	int 	x,y;
	info	myinfo;
	pthread_t	newThread;

	pthread_mutex_init(&(myinfo.mutex),NULL);
	pthread_cond_init(&(myinfo.condition),NULL);
	

	if( 0 != (errno = pthread_create( &newThread,  NULL, (void *)subthread, (void *)&myinfo)) )
	{
		fprintf(stderr,"main() : Can't create listening thread - due to :%d\n",errno);
		exit(1);
	}

	while(1)
	{	
		fprintf(stdout,"main(): sleeping....\n");
		sleep(3);		
	  	fprintf(stdout,"main(): got wake.\n");
		pthread_mutex_lock(&(myinfo.mutex));
    		pthread_cond_signal(&(myinfo.condition));
    	pthread_mutex_unlock(&(myinfo.mutex));
	}
}

void subthread(info *myinfo)
{
              struct timeval now;
              struct timespec timeout;
              int retcode;
	while(1)
	{
              now.tv_sec= time(NULL);
			  now.tv_usec=0;
              timeout.tv_sec = now.tv_sec + 1;
              timeout.tv_nsec = 0;
              retcode = 0;

              pthread_mutex_lock(&(myinfo->mutex));			  
            	  
              switch(pthread_cond_timedwait(&(myinfo->condition),&(myinfo->mutex), &timeout))
			  {
            	case 0:{	
							fprintf(stdout,"subthread(): got condition %d\n",retcode);
            	  		}
				case ETIMEDOUT: 
						{
 							fprintf(stdout,"subthread(): timed out on condition\n");
           	  			}
				}
              pthread_mutex_unlock(&(myinfo->mutex));
	}
}
