with import <nixpkgs> {};

let
  mmap-test = runCommandCC "mmap-test" {} ''
    cc -o $out ${./test.c}
  '';

  initrd = runCommand "initrd" { nativeBuildInputs = [ cpio zstd ]; } ''
    cp ${mmap-test} init
    mkdir -p nix/store
    cp -r ${stdenv.cc.cc.lib} nix/store
    cp -r ${stdenv.cc.libc} nix/store
    find . -print0 | sort -z | cpio -o -H newc -R +0:+0 --reproducible --null | zstd > $out
  '';

in writeScript "run-test" ''
  exec ${qemu}/bin/qemu-kvm -cpu max \
      -name nixos \
      -kernel arch/x86/boot/bzImage \
      -initrd ${initrd} \
      -append "console=tty0 console=ttyS0 panic=-1 nokaslr no_hash_pointers" \
      -nographic \
      -no-reboot \
      -s
''
