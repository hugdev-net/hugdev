

export KERNEL_RELEASE=$(uname -r)
export KERNEL_VERSION=$(printf "$(uname -r)" | sed  -e 's/.x86_64$//')

#下载 CentOS6 对应系统版本的安装盘 ISO 镜像
#http://archive.kernel.org/centos-vault/6.5/isos/x86_64/

wget http://archive.kernel.org/centos-vault/6.5/isos/x86_64/CentOS-6.5-x86_64-bin-DVD1.iso
wget http://archive.kernel.org/centos-vault/6.5/isos/x86_64/CentOS-6.5-x86_64-bin-DVD2.iso
wget "http://archive.kernel.org/centos-vault/6.5/os/Source/SPackages/kernel-${KERNEL_VERSION}.src.rpm"


# 挂载 DVD
sudo mkdir -p /mnt/iso1 /mnt/iso2
sudo mount -o loop -t iso9660 /path/to/CentOS-6*-DVD1.iso /mnt/iso1
sudo mount -o loop -t iso9660 /path/to/CentOS-6*-DVD2.iso /mnt/iso2

# 验证  # 应该能看到 Packages/ repodata/
ls /mnt/iso1
ls /mnt/iso2


# 添加到 yum 源
echo '
[local-media]
name=CentOS-6 Local ISOs
baseurl=file:///mnt/iso1 file:///mnt/iso2
enabled=1
gpgcheck=0
' > /etc/yum.repos.d/local-media.repo

sudo yum repolist


# 安装需要的软件包
yum install rpm-build redhat-rpm-config asciidoc hmaccalc xmlto binutils-devel newt-devel \
    python-devel perl-ExtUtils-Embed pesign elfutils-devel audit-libs-devel patchutils -y


# 安装内核源代码
rpm -i kernel-2.6.32-431.el6.src.rpm
depmod -a

#时间会长一些、大概30分钟 gpg: keyring `./pubring.gpg' created
cd ~/rpmbuild/SPECS
rpmbuild -bp kernel.spec
cd "/root/rpmbuild/BUILD/kernel-${KERNEL_VERSION}/linux-${KERNEL_RELEASE}"


# 准备内核源码
make oldconfig && make prepare && make modules_prepare


# Module.symvers文件位于当前目录
ls Module.symvers
diff ./Module.symvers "/usr/src/kernels/${KERNEL_RELEASE}/Module.symvers"
md5sum Module.symvers
md5sum "/usr/src/kernels/${KERNEL_RELEASE}/Module.symvers"
cp -i "/usr/src/kernels/${KERNEL_RELEASE}/Module.symvers" ./


# 拷贝Module.symvers到fs/fuse目录
cp Module.symvers fs/fuse/


#首次
make oldconfig
make prepare
make modules_prepare


# 编译模块
make M=fs/fuse modules


# 模块安装（注意提前备份旧模块）
cp -i ./fs/fuse/fuse.ko /lib/modules/2.6.32-642.el6.x86_64/kernel/fs/fuse/fuse.ko
