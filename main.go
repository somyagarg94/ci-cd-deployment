package main

import (
	"flag"
	"log"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/somyagarg94/helloservice/pkg/hello"
)

var addr = flag.String("addr", ":12345", "The address to listen on for HTTP requests.")

func main() {

	router := mux.NewRouter()
	router.HandleFunc("/hello:{name}", hello.GetHelloName).Methods("GET")
	log.Fatal(http.ListenAndServe(*addr, router))
}
