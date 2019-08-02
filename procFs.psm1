using namespace Microsoft.PowerShell.SHiPS

# defining root directory
class Root : SHiPSDirectory
{
    Root($name) : Base($name) {}

    [Object[]] GetChildItem(){
        $obj =  @()
        $obj += [Category]::new()
        $obj += [Author]::new()
		
		
		$obj += [cpuInfo]::new()
		
		
		
		
        return $obj
    }
}

# defining container nodes
class Category : SHiPSDirectory {

    Category():base('Category'){}

    [Object[]] GetChildItem(){
        $obj =  @()
        $obj += [PowerShell]::new()
        $obj += [Security]::new()
        return $obj
    }
}
class Author : SHiPSDirectory {

    Author():base('Author'){}

    [Object[]] GetChildItem(){
        return [Prateek]::new()
    }
}

# defining leaf nodes
class PowerShell : SHiPSLeaf {
    # define an optional leaf property
    $link =  'https://4sysops.com/tag/powershell/'
    PowerShell():base('PowerShell'){}
}

class Security : SHiPSLeaf {
    $link =  'https://4sysops.com/tag/security/'
    Security():base('Security'){}
}

class Prateek : SHiPSLeaf {
    $link =  'https://4sysops.com/members/prateeksingh/'
    Prateek():base('Prateek'){}
}



class cpuInfo : SHiPSLeaf{
	$vendor;
	
	$socket
	$processor_type
	$architecture
	$cpu_family 
	$family 
	$revision
	$version
	
	$model_name 
	$model 
	$stepping 
	
	$status
	$status_info
	
	$cpu_cores 
	$thread_count
	$logical_processors
	$address_width
	$data_width
	$external_clock
	$current_clockspeed
	$max_clock_speed
	$voltage_caps
	$level
	$power_management_supported
	
	$l2_cache_size
	$l2_cache_speed
	
	$l3_cache_size
	$l3_cache_speed
	
	$characteristics
	
	$virtualization_enabled
	$vm_monitor_mode_extensions
	
	$microcode
	
	# processor   : 0
	
	# microcode   : 0x17
	# cpu MHz     : 774.000
	# cache size  : 4096 KB
	# physical id : 0
	# siblings    : 4
	# core id     : 0
	# apicid      : 0
	# initial apicid  : 0
	# fpu     : yes
	# fpu_exception   : yes
	# cpuid level : 13
	# wp      : yes
	# flags       : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf eagerfpu pni pclmulqdq dtes64 monitor ds_cpl vmx est tm2 ssse3 fma cx16 xtpr pdcm pcid sse4_1 sse4_2 movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm ida arat epb xsaveopt pln pts dtherm tpr_shadow vnmi flexpriority ept vpid fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid
	# bogomips    : 3591.40
	# clflush size    : 64
	# cache_alignment : 64
	
	cpuInfo():base('cpuInfo'){
		$wmi = gwmi win32_processor
		
		$this.vendor = $wmi.Manufacturer
		$this.family = $wmi.Family
		$this.cpu_family = $wmi.description -split ".*Family ([0-9]+).*" -join ''
		$this.model = $wmi.description -split ".*Model ([0-9]+).*" -join ''
		$this.stepping = $wmi.description -split ".*Stepping ([0-9]+).*" -join ''
		$this.model_name = $wmi.name;
		$this.cpu_cores = $wmi.NumberOfCores
		$this.socket = $wmi.socketDesignation
		$this.processor_type = $wmi.ProcessorType
		$this.architecture = $wmi.Architecture
		$this.revision = $wmi.revision
		$this.version = $wmi.version
		$this.status = $wmi.status
		$this.status_info = $wmi.statusInfo
		$this.thread_count = $wmi.ThreadCount
		$this.logical_processors = $wmi.NumberOfLogicalProcessors
		$this.address_width = $wmi.AddressWidth
		$this.data_width = $wmi.DataWidth
		$this.external_clock = $wmi.extClock
		$this.current_clockspeed = $wmi.CurrentClockSpeed
		$this.max_clock_speed = $wmi.MaxClockSpeed
		$this.voltage_caps = $wmi.voltageCaps
		$this.level = $wmi.level
		$this.power_management_supported = $wmi.powerManagementSupported
		$this.l2_cache_size = $wmi.l2CacheSize
		$this.l2_cache_speed = $wmi.l2CacheSpeed
		$this.l3_cache_size = $wmi.l3CacheSize
		$this.l3_cache_speed = $wmi.l3CacheSpeed
		$this.characteristics = $wmi.characteristics
		$this.virtualization_enabled = $wmi.VirtualizationFirmwareEnabled
		$this.vm_monitor_mode_extensions = $wmi.VMMonitorModeExtensions
		
		
		$registrypath = "Registry::HKEY_LOCAL_MACHINE\HARDWARE\DESCRIPTION\System\CentralProcessor\0\"
		$runningMicrocode = (Get-ItemProperty -Path $registrypath )."Update Revision"
		$this.microcode = (-join ( $runningMicrocode[0..4] | foreach { $_.ToString("X2") } )).TrimStart('0')

		
		
$signature = @'
[DllImport("kernel32.dll")]
[return: MarshalAs(UnmanagedType.Bool)]
static extern bool IsProcessorFeaturePresent(ProcessorFeature processorFeature); 
'@

# $type = Add-Type -MemberDefinition $signature -Name Win32Utils -PassThru
		
		
		
		
		
		
	}
}
