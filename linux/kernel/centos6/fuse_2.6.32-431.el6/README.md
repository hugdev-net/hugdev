# 现象
- 在高并发情况下 centos6 使用fuse 应用进程 无法 kill -9 退出； 一直僵死状态，只能reboot服务器


# 问题
- 应用通过 fuse 访问外部存储
- 某种情况下，fuse 内部任务循环等待没有超时
- 导致应用调用系统函数一直处在内核态，无法正常返回
- 所以 kill -9 无法生效，应用进程无法退出


# 解决思路
- 在 fuse 内部消息循环中， 增加等待超时
- 主要是在两处 wait_event 替换成新写的 wait_event_timeout_ex

```shell
diff dev.c dev.c.bak
357,385d356
< static int ：(struct fuse_req *req, const int type) {
<     int ret = -1;
<     bool condition = false;
<     do {
<         DEFINE_WAIT(__wait);
<         unsigned long jiffies = msecs_to_jiffies(10 * 60 * 1000) + 1; /* max waits 10 minutes */
<         for (;;) {
<             prepare_to_wait(&req->waitq, &__wait, TASK_UNINTERRUPTIBLE);
<             condition = (0 == type) ? (req->state == FUSE_REQ_FINISHED) : (!req->locked);
<             if (condition) {
<                 ret = 0;
<                 break;
<             }
<             jiffies = schedule_timeout(jiffies);
<             if (0 == jiffies) {
<                 req->aborted = 1;
<                 req->out.h.error = -EIO;
<                 req->state = FUSE_REQ_FINISHED;
<                 printk(KERN_INFO "[FUSE-WARN] timeout wait_event_timeout_msec\n");
<                 ret = 1;
<                 break;
<             }
<         }
<         finish_wait(&req->waitq, &__wait);
<     } while (0);
<     return ret;
< }
<
<
431,432c402
<       /* wait_event(req->waitq, req->state == FUSE_REQ_FINISHED); */
<       wait_event_timeout_ex(req, 0);
---
>       wait_event(req->waitq, req->state == FUSE_REQ_FINISHED);
447,448c417
<               /* wait_event(req->waitq, !req->locked); */
<               wait_event_timeout_ex(req, 1);
---
>               wait_event(req->waitq, !req->locked);
```