# Changelog

## 0.9.0

- Bugfix: Timeout option matches the documentation - [Paul Hepworth](https://github.com/peppyheppy)
- Ruby 1.8 compatibility - [anujdas](https://github.com/anujdas)
- Bugfix: Omit port in host header for default ports (80, 443), so that it doesn't break some web servers, like "Apache Coyote" - [Peter Suschlik](https://github.com/splattael)
- Bugfix: Don't drop source request's port in response's location header - [Eric Koslow](https://github.com/ekosz)
- Bugfix: Capitalize headers correctly to prevent duplicate headers when used together with other proxies - [Eric Koslow](https://github.com/ekosz)
- Bugfix: Normalize headers from HttpStreamingResponse in order not to break other middlewares - [Jan Raasch](https://github.com/janraasch)
