#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/nameser.h>
#include <resolv.h>


#define MaxDNSReplyPacketSize 1024
#define MaxDNSHostNameLength 1024

static inline short getDNSShort(char *p)
{
	union {
		char b[2];
		short s;
	} u;
	short datum;

	u.b[0] = *p;
	u.b[1] = *(p + 1);

	datum = u.s;
	return ntohs(datum);
}

static inline unsigned long getDNSUnsignedLong(char *p)
{
	union {
		char b[4];
		unsigned long l;
	} u;
	unsigned long datum;

	u.b[0] = *p;
	u.b[1] = *(p + 1);
	u.b[2] = *(p + 2);
	u.b[3] = *(p + 3);

	datum = u.l;
	return ntohl(datum);
}

int nametoaddress(char *hostname)
{
	char *cp, *eom;
	struct in_addr a;
	int i, len,rlen;
	HEADER *h;
	short nquestions, nanswers, type, class;
	char name[MaxDNSHostNameLength];
	char scratch[32];
	int alias;
	char r[MaxDNSReplyPacketSize];

	if( (rlen = res_search(hostname, C_IN, T_A, r, MaxDNSReplyPacketSize)) <= 0 )
	{
		return NULL;
	}

	if (r == NULL) return NULL;
	h = (HEADER *)r;
	if (h->rcode != NOERROR) return NULL;

	nanswers = ntohs(h->ancount);
	nquestions = ntohs(h->qdcount);
	if (nanswers <= 0) return NULL;


	alias = 0;

	cp = r + sizeof(HEADER);
	eom = r + rlen;

	for (i = 0; i < nquestions; i++)
	{
		/* skip over question field [name + (short)type + (short)class] */
		len = dn_expand(r, eom, cp, name, MaxDNSHostNameLength);
		cp += len + 2 + 2;
	}

	for (i = 0; i < nanswers; i++)
	{
		len = dn_expand(r, eom, cp, name, MaxDNSHostNameLength);
		cp += len;
		type = getDNSShort(cp);
		cp += 2;
		class = getDNSShort(cp);
		cp += 2;
//		ttl = getDNSUnsignedLong(cp);
		cp += 4;


		len = getDNSShort(cp);
		cp += 2;

		switch (type)
		{
			case T_A:
				if (class == C_IN)
				{
					bcopy(cp, (char *)&a.s_addr, len);
					return inet_ntoa(a);
				}
				break;
			default:
				break;
		}
		cp += len;
	}

	return NULL;
}