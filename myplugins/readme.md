pnpm dsh web --patch ./myplugins/zero/cordis.yml
pnpm dsh web --patch ./myplugins/first/cordis.yml


```powershell
$env:DOCKER_HOST = "ssh://root@10.12.1.238"
docker cp ./myplugins/text-stats-pkg dsh-web-prod:/tmp/text-stats-pkg
docker exec dsh-web-prod sh -c "cd /data/dsh-home/profiles/web && pnpm add /tmp/text-stats-pkg"
vi /data/dsh-home/profiles/web/cordis.patch.yml
- insert:
    - id: text-stats
      name: dsh-plugin-text-stats
```

```text
编写或修改代码
调试问题
分析文件或数据
自动化任务
用文本统计工具数一下这段文字
```

```powershell
$env:DOCKER_HOST = "ssh://root@10.12.1.238"
docker exec dsh-web-prod sh -c "sed -i '/^- insert:$/,/^      name: dsh-plugin-text-stats$/d' /data/dsh-home/profiles/web/cordis.patch.yml"
docker exec dsh-web-prod sh -c "cd /data/dsh-home/profiles/web && pnpm remove dsh-plugin-text-stats"
docker restart dsh-web-prod
```