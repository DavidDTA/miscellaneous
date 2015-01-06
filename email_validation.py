import dns.exception
import dns.resolver
import errno
import socket
import smtplib

def email_address_exists_according_to_server(address):
    """
    Returns a boolean indicating whether the given email address exists according to its mail server.  This does
    not actually send mail, and may give false positives or false negatives.
    """
    (_, domain) = address.split('@')

    try:
        mx_records = dns.resolver.query(domain, 'MX')
    except dns.exception.DNSException:
        return False
    mx_records = sorted(mx_records, key=lambda x: x.preference)
    for record in mx_records:
        try:
            smtp = smtplib.SMTP(str(record.exchange))
        except smtplib.SMTPConnectError:
            continue
        except socket.error as e:
            if e.errno in [errno.ECONNREFUSED, errno.EHOSTUNREACH, errno.ETIMEDOUT]:
                continue
            raise

        try:
            helo = smtp.helo('example.com')
            if helo[0] != 250:
                return False

            mailfrom = smtp.mail('no-reply@example.com')
            if mailfrom[0] != 250:
                return False

            rcptto = smtp.rcpt(address)
            if rcptto[0] != 250:
                return False

            return True

        finally:
            try:
                smtp.quit()
            except smtplib.SMTPServerDisconnected:
                pass

    return False
