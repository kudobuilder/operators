![kudo](https://kudo.dev/images/kudo_horizontal_color@2x.png)

# KUDO Cowsay operator

The KUDO cowsay operator is a small demo for the KUDO [Pipe-Tasks](https://github.com/kudobuilder/kudo/blob/master/keps/0017-pipe-tasks.md).

### Overview

KUDO Cowsay operator:

- Uses KUOD pipe-tasks and [cowsay.morecode.org](http://cowsay.morecode.org) to generate a customized index.html 
```yaml
  - name: genwww
    kind: Pipe
    spec:
      pod: pipe-pod.yaml
      pipe:
        - file: /tmp/indexx.html
          kind: ConfigMap
          key: indexHtml
```
- Launched an nginx webserver with it


```
  ______________________________________
/ Good things come when you least expect \
\ them                                   /
  --------------------------------------
         \   ^__^ 
          \  (oo)\_______
             (__)\       )\/\
                 ||----w |
                 ||     ||
```