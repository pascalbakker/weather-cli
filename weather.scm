(import (chicken port)
        (chicken base)
        (chicken io)
        (chicken process-context)
        (chicken format)
        (chicken string))

(import openssl http-client medea json-utils intarweb uri-common)
(import http-client medea json-utils intarweb uri-common)
(import (args))

(define (f-to-c temp)
  (* (- temp 32.0) (/ 5.0 9.0)))

(define (make-nws-request url)
  (make-request method: 'GET
                uri: (uri-reference url)
                headers: (headers '((user-agent "ChickenWeatherApp/1.0")
                                    (accept "application/json")))))

(define (get-city-coords city-name)
  (let* ((normalized (string-translate city-name "," ", "))
         (encoded (uri-encode-string normalized))
         (url (sprintf "https://nominatim.openstreetmap.org/search?q=~A&format=json&limit=1" encoded))
         (response (with-input-from-request (make-nws-request url) #f read-string)))
    
    (if (not response)
        (begin (print "Error: No response") (exit 1))
        
        (let ((data (with-input-from-string response read-json)))
          (let ((results (if (vector? data) (vector->list data) data)))
            
            (if (and (list? results) (not (null? results)))
                (let ((result (car results)))
                  (let ((lat (or (alist-ref "lat" result equal?)
                                 (alist-ref 'lat result eq?)))
                        (lon (or (alist-ref "lon" result equal?)
                                 (alist-ref 'lon result eq?))))
                    (if (and lat lon)
                        (list lat lon)
                        (exit 1))))
                (begin
                  (print "Error: No results")
                  (exit 1))))))))

(define (get-grid-url lat lon)
  (let* ((url (sprintf "https://api.weather.gov/points/~A,~A" lat lon))
         (json-str (with-input-from-request (make-nws-request url) #f read-string))
         (data (with-input-from-string json-str read-json)))
    (json-ref data "properties" "forecast")))

(define (get-weather url)
  (let* ((json-str (with-input-from-request (make-nws-request url) #f read-string))
         (data (with-input-from-string json-str read-json)))
    (json-ref data "properties" "periods" 0 "temperature")))

;; TODO cache city point coords

(define (main)
  (define opts
    (list (args:make-option (c city) #:required "City name")
          (args:make-option (t type) #:optional "F or C")))
  (let* ((args-alist (args:parse (command-line-arguments) opts))
         (city       (alist-ref 'city args-alist))
         (type-val   (let ((raw (or (alist-ref 'type args-alist) "F")))
                       (if (symbol? raw)
                           (symbol->string raw)
                           raw))))
    (if (not city)
        (begin
          (print "Usage: ./weather --city \"City,State\"")
          (exit 1))
        (let* ((coords       (get-city-coords city))
               (lat          (list-ref coords 0))
               (lon          (list-ref coords 1))
               (forecast-url (get-grid-url lat lon))
               (temp         (get-weather forecast-url)))
          (begin
            (if (string-ci=? type-val "C")
                (print (round (f-to-c (exact->inexact temp))) "°C")
                (print temp "°F")))))))

(main)
