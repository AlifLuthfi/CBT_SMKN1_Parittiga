<?php
use Illuminate\Support\Facades\Schedule;
Schedule::command('exam:scheduler')->everyMinute();
