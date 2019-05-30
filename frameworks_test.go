package main

import (
	"testing"

	"github.com/kudobuilder/kudo/pkg/test"
)

// Launch the KUDO tests.
// To add more tests, add them to TestDirs belowe.
func TestKudoFrameworks(t *testing.T) {
	harness := test.Harness{
		T:         t,
		TestDirs:  []string{
			"./repository/zookeeper/tests/",
		},
		StartKUDO: true,
	}

	harness.Run()
}
