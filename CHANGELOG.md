# Changelog

## 1.0.0 (UNRELEASED)

- Breaking Change: Never modify Location headers that are only paths without hosts. [John Bachir](https://github.com/jjb) [#46](https://github.com/waterlink/rack-reverse-proxy/pull/46)
- Breaking Change: Previously, the Accept-Encoding header was stripped by default, unless the
  `preserve_encoding` option was set to true. Now, no headers are stripped by default, and an array
  of headers that should be stripped can be specified with the `stripped_headers` option.
- Breaking Change: Previously, rack-reverse-proxy had the behavior/bug that when reverse_proxy_options
  was invoked, all options that weren't set in the invokation would be set to nil. Now, those options will remain set at their default values - [Krzysztof Knapik](https://github.com/knapo) [#37](https://github.com/waterlink/rack-reverse-proxy/pull/37) and [John Bachir](https://github.com/jjb) [#47](https://github.com/waterlink/rack-reverse-proxy/pull/47)
- Breaking Change: Previously, when invoking reverse_proxy_options multiple times, only the
  final invocation would have any effect. Now, the invocations will have a commulative effect.
  [John Bachir](https://github.com/jjb) [#47](https://github.com/waterlink/rack-reverse-proxy/pull/47)
- Bugfix: Fix rack response body for https redirects [John Bachir](https://github.com/jjb) [#43](https://github.com/waterlink/rack-reverse-proxy/pull/43)

## 0.12.0

- Enhancement: Set "X-Forwarded-Proto" header to the proxying scheme. [Motonobu Kuryu](https://github.com/arc279) [#32](https://github.com/waterlink/rack-reverse-proxy/pull/32)
- Bugfix: Upgrade to a version of rack-proxy with the bug fix for the unclosed network resources. [John Bachir](https://github.com/jjb) [#45](https://github.com/waterlink/rack-reverse-proxy/pull/45)

## 0.11.0

- Breaking Change: Rename option x_forwarded_host option to x_forwarded_headers, as it controls both X-Forwarded-Port and X-Forwarded-Host - [Aurelien Derouineau](https://github.com/aderouineau) [#26](https://github.com/waterlink/rack-reverse-proxy/pull/26)
- Breaking Change: Strip Accept-Encoding header before forwarding request. [Max Gulyaev](https://github.com/maxilev) [#27](https://github.com/waterlink/rack-reverse-proxy/pull/27)

## 0.10.0

- Feature: `options[:verify_mode]` to set SSL verification mode. - [Marv Cool](https://github.com/MrMarvin) [#24](https://github.com/waterlink/rack-reverse-proxy/pull/24) and [#25](https://github.com/waterlink/rack-reverse-proxy/pull/25)

## 0.9.1

- Enhancement: Remove `Status` key from response headers as per Rack protocol (see [rack/lint](https://github.com/rack/rack/blob/master/lib/rack/lint.rb#L639)) - [Jan Raasch](https://github.com/janraasch) [#7](https://github.com/waterlink/rack-reverse-proxy/pull/7)

## 0.9.0

- Bugfix: Timeout option matches the documentation - [Paul Hepworth](https://github.com/peppyheppy)
- Ruby 1.8 compatibility - [anujdas](https://github.com/anujdas)
- Bugfix: Omit port in host header for default ports (80, 443), so that it doesn't break some web servers, like "Apache Coyote" - [Peter Suschlik](https://github.com/splattael)
- Bugfix: Don't drop source request's port in response's location header - [Eric Koslow](https://github.com/ekosz)
- Bugfix: Capitalize headers correctly to prevent duplicate headers when used together with other proxies - [Eric Koslow](https://github.com/ekosz)
- Bugfix: Normalize headers from HttpStreamingResponse in order not to break other middlewares - [Jan Raasch](https://github.com/janraasch)
