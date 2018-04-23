package hello

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestGetHelloName(t *testing.T) {
	req, err := http.NewRequest("GET", "/hello:somya", nil)
	if err != nil {
		t.Fatalf("could not created request: %v", err)
	}

	res := httptest.NewRecorder()
	GetHelloName(res, req)

	if res.Body.String() == "Hello, somya!" {
		t.Error("Expected Hello, somya! but got ", res.Body.String())
	}

}
