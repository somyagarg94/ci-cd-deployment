package hello

import (
	"fmt"
	"net/http"

	"github.com/gorilla/mux"
)

//GetHelloName returns the hello <names>.
func GetHelloName(s http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	name := vars["name"]

	s.WriteHeader(http.StatusOK)
	fmt.Fprintln(s, "Hello,", name, "!")

}
