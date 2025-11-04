package net

import (
	"io"
	gonet "net"
	"time"
)

type TimeoutListener struct {
	gonet.Listener
	ReadTimeout time.Duration
}

func (l TimeoutListener) Accept() (gonet.Conn, error) {
	c, err := l.Listener.Accept()
	if err != nil {
		return nil, err
	}

	return &TimeoutConn{Conn: c, readTimeout: l.ReadTimeout}, nil
}

type TimeoutConn struct {
	gonet.Conn
	readTimeout time.Duration
	bodyDone    bool
}

// Read implements a read with a sliding timeout window.
func (c *TimeoutConn) Read(b []byte) (int, error) {
	if c.readTimeout > 0 && !c.bodyDone {
		if err := c.SetReadDeadline(time.Now().Add(c.readTimeout)); err != nil {
			return 0, err
		}
	}

	n, err := c.Conn.Read(b)
	if n > 0 && c.readTimeout > 0 && !c.bodyDone {
		// reset deadline after every successful read
		_ = c.SetReadDeadline(time.Now().Add(c.readTimeout))
	}

	if err == io.EOF {
		c.bodyDone = true
	}
	return n, err
}
