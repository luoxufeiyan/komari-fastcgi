package main

import (
	"io"
	"log"
	"log/slog"
	"os"

	"github.com/komari-monitor/komari/cmd"
	"github.com/komari-monitor/komari/internal/conf"
	logutil "github.com/komari-monitor/komari/internal/log"
)

func main() {
	// 检查是否显式禁用 FastCGI 模式
	isFCGI := true // 默认为 true
	for _, arg := range os.Args {
		if arg == "--fcgi=false" {
			isFCGI = false
			break
		}
	}
	
	// 如果不是 FastCGI 模式，才设置日志和输出版本信息
	if !isFCGI {
		if conf.Version == conf.Version_Development {
			logutil.SetupGlobalLogger(slog.LevelDebug)
		} else {
			logutil.SetupGlobalLogger(slog.LevelInfo)
		}
		log.Printf("Komari Monitor %s (hash: %s)", conf.Version, conf.CommitHash)
	} else {
		// FastCGI 模式下将所有日志输出到文件
		// 打开专用的调试日志文件
		f, err := os.OpenFile("fcgi_debug.log", os.O_RDWR|os.O_CREATE|os.O_APPEND, 0666)
		if err != nil {
			// 如果无法打开日志文件，回退到 discard
			log.SetOutput(io.Discard)
			logutil.SetupGlobalLoggerWithOutput(io.Discard, slog.LevelError)
		} else {
			// 将标准库的日志重定向到文件
			log.SetOutput(f)
			// 将 slog 也重定向到文件
			logutil.SetupGlobalLoggerWithOutput(f, slog.LevelDebug)
			log.Println("FastCGI 模式启动，日志记录到 fcgi_debug.log")
			log.Printf("Komari Monitor %s (hash: %s)", conf.Version, conf.CommitHash)
		}
	}

	cmd.Execute()
}
