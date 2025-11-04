package http

import (
	"net"
	"time"
)

type timeoutListener struct {
	net.Listener
	readTimeout time.Duration
}

func (tl timeoutListener) Accept() (net.Conn, error) {
	c, err := tl.Listener.Accept()
	if err != nil {
		return nil, err
	}
	return &timeoutConn{Conn: c, readTimeout: tl.readTimeout}, nil
}

type timeoutConn struct {
	net.Conn
	readTimeout time.Duration
}

// Read implements a read with sliding timeout window.
func (c *timeoutConn) Read(b []byte) (int, error) {
	if c.readTimeout > 0 {
		_ = c.SetReadDeadline(time.Now().Add(c.readTimeout))
	}
	return c.Conn.Read(b)
}
