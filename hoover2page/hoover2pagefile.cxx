#include <stdio.h>
#include <string.h>
#include <errno.h>
#include "fprint.h"
//#include <libc.h>

#define NUMBEROFPAGESPERFILE 50000

char *header = "HTTP/1.1 200 OK\nDate: Sat, 08 Aug 1998 08:11:24 GMT\nServer: Apache/1.2.0\nContent-Type: text/html\n";
	


int main(int argc, char **argv) 
{
	FILE		*hooverfile, *pagefile;
	char		pagefilename[1024];
	char		stringbuffer[1024];
	char 		url[1000];
	long		httpdatabegin,httpdataend;
	int			wroteall;
	int			numberofpageswritten;
	fprint_t	fingerprint;
	fprint_init();
	
	

	if( 2!=argc )
	{
		fprintf(stderr,"usage: %s hooverinputfilename\n",argv[0]);
		return 1;
	}
	
	if( NULL == (hooverfile=fopen(argv[1],"r")) )
	{
		fprintf(stderr,"Unable to open %s\n", argv[1]);
		return 1;
	}
			
	fseek(hooverfile,0,SEEK_SET);
	httpdatabegin = 0;
	wroteall = 0;
	numberofpageswritten = 0;
	pagefile = NULL;
	
	while( !wroteall )
	{
		stringbuffer[1022]=0;
		stringbuffer[1023]=0;
		
		if( feof(hooverfile) || (NULL != (fgets(stringbuffer,1024,hooverfile))) )
		{
			if(! feof(hooverfile))
			{
				if( ('\n' == stringbuffer[0]) && (ftell(hooverfile) == httpdatabegin+2) )
				{
					httpdatabegin++;
				}
				
				stringbuffer[strlen(stringbuffer)-1]=0;

				if( 0 == strncmp(stringbuffer,"Hoover-Httpdata:",16) )
				{
					httpdatabegin = ftell(hooverfile);
				}
			}				
			else
			{
				wroteall=feof(hooverfile);
				strcpy(stringbuffer,"Hoover-Url:endoffileurl");
			}
			
			if( 0 == strncmp(stringbuffer,"Hoover-Url:",11) )
			{
				unsigned char	*copybuffer;
				long	body_size,header_size;
				long	positioninhooverfile = ftell(hooverfile);
				long	i;
				
				header_size = strlen(header);
				if(! feof(hooverfile) )
					httpdataend = positioninhooverfile - strlen(stringbuffer) -1;
				else
					httpdataend = positioninhooverfile;
				body_size = (httpdataend-httpdatabegin);

				if( httpdatabegin !=0 )
				{
					if( 0 == numberofpageswritten%NUMBEROFPAGESPERFILE )
					{
						if( NULL != pagefile )
						{
							fclose(pagefile);
							fprintf(stderr,"%s closed.\n",pagefilename);	
						}
						sprintf(pagefilename, "%s.page.%d", argv[1],numberofpageswritten/NUMBEROFPAGESPERFILE);
						if( NULL == (pagefile=fopen(pagefilename,"w")))
						{
							fprintf(stderr,"Unable to open %s\n", pagefilename);
							return(1);
						}
					}
				
					fprintf(pagefile,"@ + http://%s %lx %x %d %d %d\n%s\n", url, fprint_fromstr(url), 0, 1, header_size, body_size, header);
					if(body_size <=0)
					{
						fprintf(stderr,"Bodysize = %d begin %d end %d\n",body_size,httpdatabegin,httpdataend);
						exit(1);
					}
					if( NULL == (copybuffer = (char *)malloc(body_size)) )
					{
						fprintf(stderr,"Couldn't malloc\n");
						exit(1);
					}
					fseek(hooverfile,httpdatabegin,SEEK_SET);
					if( body_size != fread(copybuffer,1, body_size,hooverfile) )
					{
						fprintf(stderr,"Error reading httpdata to memory\n");
						exit(1);
					}
					
					for(i=0;i<body_size;i++)
					{
						if(copybuffer[i]<0x20)
						{
							switch(copybuffer[i])
							{
								case	'\n'	:	break;
								case	'\r'	:	break;
								case	'\t'	:	break;
								default			:	copybuffer[i]=0x20;
							}
						}
						else
						{
							if(copybuffer[i]>0x7f && copybuffer[i]<0xa0)
							{
								copybuffer[i]=0x20;
							}
						}

					}

					if( body_size != fwrite(copybuffer,1, body_size,pagefile) )
					{
						fprintf(stderr,"Error writing httpdata to pagefile\n");
						exit(1);
					}
					fputc('\n',pagefile);
					free(copybuffer);
					numberofpageswritten++;
				}
				strcpy(url,stringbuffer+11);
				//fprintf(stderr,"Found new url:%s\n",url);
				fseek(hooverfile,positioninhooverfile,SEEK_SET);
			}
		}
	}
	fclose(hooverfile);
	fclose(pagefile);


	return 0;
}
