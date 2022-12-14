//+------------------------------------------------------------------+
//|                                                 TCandleClose.mq5 |
//|															 haxpor. |
//|                                                 https://wasin.io |
//+------------------------------------------------------------------+
#property copyright "MIT 2022, haxpor."
#property link      "https://wasin.io"
#property version   "1.07"

#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots 0

// name of the label object representing a time remaining
#define TIME_LABEL_NAME "Time Label"

input int inp_label_xdistance = 30;			// X distance from upper right corner
input int inp_label_ydistance = 50;				// Y distance from upper right corner
input int inp_label_fontsize = 23;				// Font size of the label
input color inp_label_tint_color = clrWhite;      // Tint color for label text.
input bool inp_label_hidden = false;			// Show or hide the label (true = hide)

bool is_prev_detected_market_close = false;

/**
  Setup main label object representing a time remaining on the main chart.

  Parameters
  - obj_name - name of the object
**/
void SetupLabelObject(string obj_name) {
	ObjectCreate(0, obj_name, OBJ_LABEL, 0, 0, 0);
	ObjectSetInteger(0, obj_name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
	ObjectSetInteger(0, obj_name, OBJPROP_XDISTANCE, inp_label_xdistance);
	ObjectSetInteger(0, obj_name, OBJPROP_YDISTANCE, inp_label_ydistance);
	ObjectSetInteger(0, obj_name, OBJPROP_FONTSIZE, inp_label_fontsize);
	
	// set the color for label text to be contrast with the chart background
	color suggested_label_txt_color = (color)ChartGetInteger(0, CHART_COLOR_BACKGROUND) ^ 0xFFFFFF;
	if (suggested_label_txt_color == 0x000000)
	   ObjectSetInteger(0, obj_name, OBJPROP_COLOR, inp_label_tint_color);
	else
	   ObjectSetInteger(0, obj_name, OBJPROP_COLOR, (color)(suggested_label_txt_color & inp_label_tint_color));
	
	ObjectSetInteger(0, obj_name, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
	// there is no property to show/hide an object, we use visiblity on timeframes to solve it
	if (inp_label_hidden)
		ObjectSetInteger(0, obj_name, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
	else
		ObjectSetInteger(0, obj_name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
	// only update text when it is newly created
	ObjectSetString(0, obj_name, OBJPROP_TEXT, " ");		// at least has to be space to not let it have "Label" text automatically
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
	// 1 second fixed interval for update time remaining
	SetupLabelObject(TIME_LABEL_NAME);
	EventSetTimer(1);
	
	return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
	ObjectDelete(0, TIME_LABEL_NAME);
	EventKillTimer();

	is_prev_detected_market_close = false;
}

/**
  Get total seconds from timeframe.

  Parameters
  * tf - time frame in type `ENUM_TIMEFRAMES`
  * dt - date time in question.

  Return
  Total seconds represents such timeframe. Return -1 for PERIOD_CURRENT.
**/
int GetTotalSecondsFromTimeframe(ENUM_TIMEFRAMES tf, const MqlDateTime& dt) {
	switch (tf) {
	case PERIOD_M1:
		return 60;
	case PERIOD_M2:
		return 60*2;
	case PERIOD_M3:
		return 60*3;
	case PERIOD_M4:
		return 60*4;
	case PERIOD_M5:
		return 60*5;
	case PERIOD_M6:
		return 60*6;
	case PERIOD_M10:
		return 60*10;
	case PERIOD_M12:
		return 60*12;
	case PERIOD_M15:
		return 60*15;
	case PERIOD_M20:
		return 60*20;
	case PERIOD_M30:
		return 60*30;
	case PERIOD_H1:
		return 60*60;
	case PERIOD_H2:
		return 2*60*60;
	case PERIOD_H3:
		return 3*60*60;
	case PERIOD_H4:
		return 4*60*60;
	case PERIOD_H6:
		return 6*60*60;
	case PERIOD_H8:
		return 8*60*60;
	case PERIOD_H12:
		return 12*60*60;
	case PERIOD_D1:
		return 24*60*60;
	case PERIOD_W1:
		return 7*24*60*60;
	case PERIOD_MN1:
		if (dt.mon == 2) {
			if (dt.year % 4 == 0)
				return 29*24*60*60;
			else
				return 28*24*60*60;
		}
		else {
			int month = dt.mon;
			if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
				return 31*24*60*60;
			}
			else {
				return 30*24*60*60;
			}
		}
	default:
		return -1;
	}
}

/**
	Get leading zero from input number if necessary.
**/
string LeadingZero(int n) {
	if (n < 10)
		return "0" + IntegerToString(n);
	else
		return IntegerToString(n);
}

/**
  Get enum value of day of week.

  Input
	- dow - integer value of day of week
	- out_dow - output value written with enum value of day of week

  Return
  True if success with written result of day of week into `out_dow`, otherwise false ignoring `out_dow`.
**/
bool DayOfWeekEnum(int dow, ENUM_DAY_OF_WEEK& out_dow) {
	switch (dow) {
	case 0:
		out_dow = SUNDAY;
		return true;
	case 1:
		out_dow = MONDAY;
		return true;
	case 2:
		out_dow = TUESDAY;
		return true;
	case 3:
		out_dow = WEDNESDAY;
		return true;
	case 4:
		out_dow = THURSDAY;
		return true;
	case 5:
		out_dow = FRIDAY;
		return true;
	case 6:
		out_dow = SATURDAY;
		return true;
	default:
		return false;
	}
}

/**
  Hour-Minute-Second comparator functor for MqlDateTime.
**/
struct MqlDateTimeHMSComparator {
	// mql5 doesn't allow empty struct to be defined
	char _dummy;
	
	bool compare_lt(const MqlDateTime& dt1, const MqlDateTime& dt2) {
		return dt1.hour < dt2.hour ||
			   (dt1.hour == dt2.hour && dt1.min < dt2.min) ||
			   (dt1.hour == dt2.hour && dt1.min == dt2.min && dt1.sec < dt2.sec);
	}

	bool compare_gt(const MqlDateTime& dt1, const MqlDateTime& dt2) {
		return dt1.hour > dt2.hour ||
			   (dt1.hour == dt2.hour && dt1.min > dt2.min) ||
			   (dt1.hour == dt2.hour && dt1.min == dt2.min && dt1.sec > dt2.sec);
	}

	bool compare_lt_or_eq(const MqlDateTime& dt1, const MqlDateTime& dt2) {
		return dt1.hour <= dt2.hour ||
			   (dt1.hour == dt2.hour && dt1.min <= dt2.min) ||
			   (dt1.hour == dt2.hour && dt1.min == dt2.min && dt1.sec <= dt2.sec);
	}

	bool compare_gt_or_eq(const MqlDateTime& dt1, const MqlDateTime& dt2) {
		return dt1.hour >= dt2.hour ||
			   (dt1.hour == dt2.hour && dt1.min >= dt2.min) ||
			   (dt1.hour == dt2.hour && dt1.min == dt2.min && dt1.sec >= dt2.sec);
	}

	bool compare_eq(const MqlDateTime& dt1, const MqlDateTime& dt2) {
		return dt1.hour == dt2.hour && dt1.min == dt2.min && dt1.sec == dt2.sec;
	}
};

// Compute remaining time from the input of datetime.
void ComputeRemainingTime(datetime t) {
	// Phase 1: Checking for market close
	MqlDateTime time_st;
	// advance ahead by one second as we base on using TimeCurrent() which only return latest receipt of date/time
	// of the quote, it doesn't return non-operating hours. So we can check for market close ahead by 1 sec from the
	// current valid trading session minute.
	if (!TimeToStruct(t+1, time_st)) {	
		Print("Error TimeToStruct()");
		return;
	}
	// check if market closed, so there should be no calculations
	datetime trade_session_from, trade_session_to;
	MqlDateTime trade_session_from_dt, trade_session_to_dt;
	ENUM_DAY_OF_WEEK dow;

	if (!DayOfWeekEnum(time_st.day_of_week, dow)) {
		Print("Error getting day of week via DayOfWeek()");
		return;
	}

	// NOTE: this function returns error if query for non-operating "day" of target instruments i.e. weekends for most
	// instruments. As our approach bases on using TimeCurrent(), it won't ever return non-operating date/time, so the
	// case of returning error helps us in detecting market closed.
	if (!SymbolInfoSessionTrade(Symbol(), dow, 0, trade_session_from, trade_session_to)) {
		// not print anything to not spam log message on user side
		return;
	}
	if (!TimeToStruct(trade_session_from, trade_session_from_dt)) {
		Print("Error getting MqlDateTime from datetime for trade_session_from");
		return;
	}
	if (!TimeToStruct(trade_session_to, trade_session_to_dt)) {
		Print("Error getting MqlDateTime from datetime for trade_session_to");
		return;
	}

	MqlDateTimeHMSComparator mdt_comparator;
	if (mdt_comparator.compare_lt(time_st, trade_session_from_dt) || mdt_comparator.compare_gt(time_st, trade_session_to_dt)) {
		// only empty when necessary to not overwhelming finding a particular object which is expensive if do it frequently
		if (!is_prev_detected_market_close) {
			// not necessary to print anything here as it's outside of this indicator's responsibility, just hide the label
			// by emptying the text
			ObjectSetString(0, TIME_LABEL_NAME, OBJPROP_TEXT, " ");		// at least has to be space to not let it have "Label" text automatically
			ChartRedraw(0);
		}
		is_prev_detected_market_close = true;
		return;
	}
	else {
		is_prev_detected_market_close = false;
	}

	// Phase 2: Updating time remaining
	if (!TimeToStruct(t, time_st)) {
		Print("Error TimeToStruct()");
		return;
	}
	// convert current time to seconds
	int total_secs = time_st.hour*60*60 + time_st.min*60 + time_st.sec;

	// get total seconds from current period
	int period_total_secs = GetTotalSecondsFromTimeframe(Period(), time_st);

	// handle the printing format as follows
	// DD:HH:MM:SS in case of PERIOD_W1 or PERIOD_MN1
	// HH:MM:SS in case of others
	ENUM_TIMEFRAMES period = Period();
	if (period == PERIOD_W1 || period == PERIOD_MN1) {
		// find the total days of period
		int period_days = (int)MathFloor(period_total_secs / (24*60*60));		// find total days of the period

		// adjust total_secs as it doesn't take into account "days" yet
		total_secs += time_st.day*24*60*60;

		// find remaining seconds
		int remaining_total_secs = period_total_secs - 1 - (total_secs % period_total_secs);	// minus 1 to not finally display next higher unit when counted down to zero

		// find hour, minute, and sec
		int r_sec = remaining_total_secs % 60;
		int r_min = (int)MathFloor(remaining_total_secs/60.0) % 60;
		int r_hour = (int)MathFloor(remaining_total_secs/(60.0*60.0)) % 24;
		int r_day = (int)MathFloor(remaining_total_secs/(24*60.0*60.0)) % period_days;

		ObjectSetString(0, TIME_LABEL_NAME, OBJPROP_TEXT, LeadingZero(r_day) + ":" + LeadingZero(r_hour) + ":" + LeadingZero(r_min) + ":" + LeadingZero(r_sec));
	}
	else {
		// find remaining seconds
		int remaining_total_secs = period_total_secs - 1 - (total_secs % period_total_secs);	// minus 1 to not finally display next higher unit when counted down to zero

		// find hour, minute, and sec
		int r_sec = remaining_total_secs % 60;
		int r_min = (int)MathFloor(remaining_total_secs/60.0) % 60;
		int r_hour = (int)MathFloor(remaining_total_secs/(60.0*60.0)) % 24;

		ObjectSetString(0, TIME_LABEL_NAME, OBJPROP_TEXT, LeadingZero(r_hour) + ":" + LeadingZero(r_min) + ":" + LeadingZero(r_sec));
	}

	// force redrawing of main chart
	// usually it would be called after chaning object's properties, but it didn't work for us thus we force it here
	// to fix an issue of time remaining not updated every second (every elapse of timer)
	ChartRedraw(0);
}

void OnTimer() {
	ComputeRemainingTime(TimeCurrent());
}

int OnCalculate(const int rates_total,
				 const int prev_calculated,
				 const int begin,
				 const double& price[]) {
	// empty, indicator type of program requires to have this function defined
	return rates_total;
}
