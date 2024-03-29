function Get-CpuId {
  begin {
    ($psdll = New-PSDllObject).set(@(
      [Runtime.InteropServices.GCHandle],
      [Runtime.InteropServices.Marshal]
    ))
    
    $VirtualAlloc = $psdll.def(
      'kernel32', 'VirtualAlloc',
      '[Func[IntPtr, UIntPtr, UInt32, UInt32, IntPtr]]'
    )
    
    $VirtualFree = $psdll.def(
      'kernel32', 'VirtualFree',
      '[Func[IntPtr, UIntPtr, UInt32, Boolean]]'
    )
    
    [Byte[]]$bytes = switch ([IntPtr]::Size) {
      4 {
        0x55,                   #push  ebp
        0x8B, 0xEC,             #mov   ebp,  esp
        0x53,                   #push  ebx
        0x57,                   #push  edi
        0x8B, 0x45, 0x08,       #mov   eax,  dword ptr[ebp+8]
        0x0F, 0xA2,             #cpuid
        0x8B, 0x7D, 0x0C,       #mov   edi,  dword ptr[ebp+12]
        0x89, 0x07,             #mov   dword ptr[edi+0],  eax
        0x89, 0x5F, 0x04,       #mov   dword ptr[edi+4],  ebx
        0x89, 0x4F, 0x08,       #mov   dword ptr[edi+8],  ecx
        0x89, 0x57, 0x0C,       #mov   dword ptr[edi+12], edx
        0x5F,                   #pop   edi
        0x5B,                   #pop   ebx
        0x8B, 0xE5,             #mov   esp,  ebp
        0x5D,                   #pop   ebp
        0xC3                    #ret
      }
      8 {
        0x53,                   #push  rbx
        0x49, 0x89, 0xD0,       #mov   r8,  rdx
        0x89, 0xC8,             #mov   eax, ecx
        0x0F, 0xA2,             #cpuid
        0x41, 0x89, 0x40, 0x00, #mov   dword ptr[r8+0],  eax
        0x41, 0x89, 0x58, 0x04, #mov   dword ptr[r8+4],  ebx
        0x41, 0x89, 0x48, 0x08, #mov   dword ptr[r8+8],  ecx
        0x41, 0x89, 0x50, 0x0C, #mov   dword ptr[r8+12], edx
        0x5B,                   #pop   rbx
        0xC3                    #ret
      }
    }
    
    $features = @{}
  }
  process {
    try {
      $ptr = $VirtualAlloc.Invoke(
        [IntPtr]::Zero, (New-Object UIntPtr($bytes.Length)),
        (0x1000 -bor 0x2000), 0x40
      )
      
      [Marshal]::Copy($bytes, 0, $ptr, $bytes.Length)
      
      [Byte[]]$buf = New-Object Byte[](16)
      $gch = [GCHandle]::Alloc($buf, 'Pinned')
      $psdll.cpuid(0, $buf)
      $gch.Free()
      # cpu vendor
      $vendor = "$(($str = $psdll.blocks(
        $buf, $false, $true
      )).ebx)$($str.edx)$($str.ecx)"
      # low leaves
      $ids =  $psdll.blocks($buf, $true, $false).eax
      $low = @()
      for ($i = 0; $i -le $ids; $i++) {
        $psdll.cpuid($i, $buf)
        
        if ($i -eq 1) {
          $reg = $psdll.blocks($buf, $true, $false)
          
          $stepping = $reg.eax -band 0xF
          $model    = $psdll.shift('Right').Invoke($reg.eax, 4) -band 0xF
          $family   = $psdll.shift('Right').Invoke($reg.eax, 8) -band 0xF
          $logiccpu = $psdll.shift('Right').Invoke($reg.ebx, 16) -band 0xFF
          
          $features['fpu']          = $reg.edx -band 0x00000001
          $features['vme']          = $reg.edx -band 0x00000002
          $features['de']           = $reg.edx -band 0x00000004
          $features['pse']          = $reg.edx -band 0x00000008
          $features['tsc']          = $reg.edx -band 0x00000010
          $features['msr']          = $reg.edx -band 0x00000020
          $features['pae']          = $reg.edx -band 0x00000040
          $features['mce']          = $reg.edx -band 0x00000080
          $features['cx8']          = $reg.edx -band 0x00000100
          $features['apic']         = $reg.edx -band 0x00000200
          $features['sep']          = $reg.edx -band 0x00000800
          $features['mtrr']         = $reg.edx -band 0x00001000
          $features['pge']          = $reg.edx -band 0x00002000
          $features['mca']          = $reg.edx -band 0x00004000
          $features['cmov']         = $reg.edx -band 0x00008000
          $features['pat']          = $reg.edx -band 0x00010000
          $features['pse_36']       = $reg.edx -band 0x00020000
          $features['psn']          = $reg.edx -band 0x00040000
          $features['clflush']      = $reg.edx -band 0x00080000
          $features['ds']           = $reg.edx -band 0x00200000
          $features['acpi']         = $reg.edx -band 0x00400000
          $features['mmx']          = $reg.edx -band 0x00800000
          $features['fxsr']         = $reg.edx -band 0x01000000
          $features['sse']          = $reg.edx -band 0x02000000
          $features['sse2']         = $reg.edx -band 0x04000000
          $features['ss']           = $reg.edx -band 0x08000000
          $features['htt']          = $reg.edx -band 0x10000000
          $features['tm']           = $reg.edx -band 0x20000000
          $features['ia64']         = $reg.edx -band 0x40000000
          $features['pbe']          = $reg.edx -band 0x80000000
          
          $features['sse3']         = $reg.ecx -band 0x00000001
          $features['pclmulqdq']    = $reg.ecx -band 0x00000002
          $features['dtes64']       = $reg.ecx -band 0x00000004
          $features['monitor']      = $reg.ecx -band 0x00000008
          $features['ds_cpl']       = $reg.ecx -band 0x00000010
          $features['vmx']          = $reg.ecx -band 0x00000020
          $features['smx']          = $reg.ecx -band 0x00000040
          $features['est']          = $reg.ecx -band 0x00000080
          $features['tm2']          = $reg.ecx -band 0x00000100
          $features['ssse3']        = $reg.ecx -band 0x00000200
          $features['cntx_id']      = $reg.ecx -band 0x00000400
          $features['sdbg']         = $reg.ecx -band 0x00000800
          $features['fma']          = $reg.ecx -band 0x00001000
          $features['cx16']         = $reg.ecx -band 0x00002000
          $features['xtpr']         = $reg.ecx -band 0x00004000
          $features['pdcm']         = $reg.ecx -band 0x00008000
          $features['pcid']         = $reg.ecx -band 0x00020000
          $features['dca']          = $reg.ecx -band 0x00040000
          $features['sse4_1']       = $reg.ecx -band 0x00080000
          $features['sse4_2']       = $reg.ecx -band 0x00100000
          $features['x2apic']       = $reg.ecx -band 0x00200000
          $features['movbe']        = $reg.ecx -band 0x00400000
          $features['popcnt']       = $reg.ecx -band 0x00800000
          $features['tsc_deadline'] = $reg.ecx -band 0x01000000
          $features['aes']          = $reg.ecx -band 0x02000000
          $features['xsave']        = $reg.ecx -band 0x04000000
          $features['osxsave']      = $reg.ecx -band 0x08000000
          $features['avx']          = $reg.ecx -band 0x10000000
          $features['f16c']         = $reg.ecx -band 0x20000000
          $features['rdrnd']        = $reg.ecx -band 0x40000000
          $features['hypervisor']   = $reg.ecx -band 0x80000000
        }
        
        $leave = New-Object PSObject -Property $psdll.blocks($buf, $true, $false)
        $leave.PSObject.TypeNames.Insert(0, 'CpuIdLeave')
        $low += $leave
      }
      # high leaves
      $psdll.cpuid(0x80000000, $buf)
      $ids = $psdll.blocks($buf, $true, $false).eax
      $top = @()
      $name = '' # brand string
      for ($i = 0x80000000; $i -le $ids; $i++) {
        $psdll.cpuid($i, $buf)
        
        if ($i -eq 0x80000001) {
          $reg = $psdll.blocks($buf, $true, $false)
          
          $features['syscall']       = $reg.edx -band 0x00000800
          $features['mp']            = $reg.edx -band 0x00080000
          $features['nx']            = $reg.edx -band 0x00100000
          $features['mmxext']        = $reg.edx -band 0x00400000
          $features['fxsr_opt']      = $reg.edx -band 0x02000000
          $features['pdpe1gb']       = $reg.edx -band 0x04000000
          $features['rdtscp']        = $reg.edx -band 0x08000000
          $features['lm']            = $reg.edx -band 0x20000000
          $features['3dnowext']      = $reg.edx -band 0x40000000
          $features['3dnow']         = $reg.edx -band 0x80000000
          
          $features['lahf_lm']       = $reg.ecx -band 0x00000001
          $features['cmp_legacy']    = $reg.ecx -band 0x00000002
          $features['svm']           = $reg.ecx -band 0x00000004
          $features['extapic']       = $reg.ecx -band 0x00000008
          $features['cr8_legacy']    = $reg.ecx -band 0x00000010
          $features['abm']           = $reg.ecx -band 0x00000020
          $features['sse4a']         = $reg.ecx -band 0x00000040
          $features['misalingsse']   = $reg.ecx -band 0x00000080
          $features['3dnowprefetch'] = $reg.ecx -band 0x00000100
          $features['osvw']          = $reg.ecx -band 0x00000200
          $features['ibs']           = $reg.ecx -band 0x00000400
          $features['xop']           = $reg.ecx -band 0x00000800
          $features['skinit']        = $reg.ecx -band 0x00001000
          $features['wdt']           = $reg.ecx -band 0x00002000
          $features['lwp']           = $reg.ecx -band 0x00008000
          $features['fma4']          = $reg.ecx -band 0x00010000
          $features['tce']           = $reg.ecx -band 0x00020000
          $features['nodeid_msr']    = $reg.ecx -band 0x00080000
          $features['tbm']           = $reg.ecx -band 0x00200000
          $features['topoext']       = $reg.ecx -band 0x00400000
          $features['perfctr_core']  = $reg.ecx -band 0x00800000
          $features['perfctr_nb']    = $reg.ecx -band 0x01000000
          $features['dbx']           = $reg.ecx -band 0x04000000
          $features['perftsc']       = $reg.ecx -band 0x08000000
          $features['pcx_l2i']       = $reg.ecx -band 0x10000000
        }
        
        if ($i -eq 0x80000002 -or $i -eq 0x80000003 -or $i -eq 0x80000004) {
          $name += "$(($reg = $psdll.blocks(
            $buf, $false, $true
          )).eax)$($reg.ebx)$($reg.ecx)$($reg.edx)"
        }
        
        if ($i -eq 0x80000006) {
          $reg = $psdll.blocks($buf, $true, $false)
          $cachelsz  = $reg.ecx -band 0xFF
          $l2assoc   = $psdll.shift('Right').Invoke($reg.ecx, 12) -band 0xF
          $l2cachesz = $psdll.shift('Right').Invoke($reg.ecx, 16) -band 0xFFFF
        }
        
        $leave = New-Object PSObject -Property $psdll.blocks($buf, $true, $false)
        $leave.PSObject.TypeNames.Insert(0, 'CpuIdLeave')
        $top += $leave
      }
      
      $cpuid = New-Object PSObject -Property @{
        Vendor          = $vendor
        Name            = $name.Trim()
        SteppingId      = $stepping
        Model           = $model
        Family          = $family
        LogicalCpuCount = $logiccpu
        L2CacheSize     = $l2cachesz
        L2Associativity = $l2assoc
        CacheLineSize   = $cachelsz
        Features        = $features.Keys | ForEach-Object {
          if ($features[$_]) { $_ }
        } | Sort-Object
        LowLeaves       = $low
        HighLeaves      = $top
      }
      $cpuid.PSObject.TypeNames.Insert(0, 'CpuId')
      $cpuid
    }
    finally {
      if ($ptr) {
        [void]$VirtualFree.Invoke($ptr, [UIntPtr]::Zero, 0x8000)
      }
    }
  }
  end {
    $psdll.free()
  }
}
